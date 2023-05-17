import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import runnerDeleteMutation from '~/ci/runner/graphql/shared/runner_delete.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import { I18N_DELETE_RUNNER } from '~/ci/runner/constants';

import RunnerDeleteButton from '~/ci/runner/components/runner_delete_button.vue';
import RunnerDeleteModal from '~/ci/runner/components/runner_delete_modal.vue';
import { allRunnersData } from '../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];
const mockRunnerId = getIdFromGraphQLId(mockRunner.id);
const mockRunnerName = `#${mockRunnerId} (${mockRunner.shortSha})`;

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

describe('RunnerDeleteButton', () => {
  let wrapper;
  let apolloProvider;
  let apolloCache;
  let runnerDeleteHandler;

  const findBtn = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(RunnerDeleteModal);

  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;
  const getModal = () => getBinding(findBtn().element, 'gl-modal').value;

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    const { runner, ...propsData } = props;

    wrapper = mountFn(RunnerDeleteButton, {
      propsData: {
        runner: {
          // We need typename so that cache.identify works
          // eslint-disable-next-line no-underscore-dangle
          __typename: mockRunner.__typename,
          id: mockRunner.id,
          shortSha: mockRunner.shortSha,
          ...runner,
        },
        ...propsData,
      },
      apolloProvider,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
        GlModal: createMockDirective('gl-modal'),
      },
    });
  };

  const clickOkAndWait = async () => {
    findModal().vm.$emit('primary');
    await waitForPromises();
  };

  beforeEach(() => {
    runnerDeleteHandler = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        data: {
          runnerDelete: {
            errors: [],
          },
        },
      });
    });
    apolloProvider = createMockApollo([[runnerDeleteMutation, runnerDeleteHandler]]);
    apolloCache = apolloProvider.defaultClient.cache;

    jest.spyOn(apolloCache, 'evict');
    jest.spyOn(apolloCache, 'gc');

    createComponent();
  });

  it('Displays a delete button without an icon', () => {
    expect(findBtn().props()).toMatchObject({
      loading: false,
      icon: '',
    });
    expect(findBtn().classes('btn-icon')).toBe(false);
    expect(findBtn().text()).toBe(I18N_DELETE_RUNNER);
  });

  it('Displays a modal with the runner name', () => {
    expect(findModal().props('runnerName')).toBe(mockRunnerName);
  });

  it('Does not have tabindex when button is enabled', () => {
    expect(wrapper.attributes('tabindex')).toBeUndefined();
  });

  it('Displays a modal when clicked', () => {
    const modalId = `delete-runner-modal-${mockRunnerId}`;

    expect(getModal()).toBe(modalId);
    expect(findModal().attributes('modal-id')).toBe(modalId);
  });

  it('Does not display redundant text for screen readers', () => {
    expect(findBtn().attributes('aria-label')).toBe(undefined);
  });

  it('Passes other attributes to the button', () => {
    createComponent({ props: { category: 'secondary' } });

    expect(findBtn().props('category')).toBe('secondary');
  });

  describe(`Before the delete button is clicked`, () => {
    it('The mutation has not been called', () => {
      expect(runnerDeleteHandler).toHaveBeenCalledTimes(0);
    });
  });

  describe('Immediately after the delete button is clicked', () => {
    beforeEach(() => {
      findModal().vm.$emit('primary');
    });

    it('The button has a loading state', () => {
      expect(findBtn().props('loading')).toBe(true);
    });

    it('The stale tooltip is removed', () => {
      expect(getTooltip()).toBe('');
    });
  });

  describe('After clicking on the delete button', () => {
    beforeEach(async () => {
      await clickOkAndWait();
    });

    it('The mutation to delete is called', () => {
      expect(runnerDeleteHandler).toHaveBeenCalledTimes(1);
      expect(runnerDeleteHandler).toHaveBeenCalledWith({
        input: {
          id: mockRunner.id,
        },
      });
    });

    it('The user can be notified with an event', () => {
      const deleted = wrapper.emitted('deleted');

      expect(deleted).toHaveLength(1);
      expect(deleted[0][0].message).toMatch(`#${mockRunnerId}`);
      expect(deleted[0][0].message).toMatch(`${mockRunner.shortSha}`);
    });

    it('evicts runner from apollo cache', () => {
      expect(apolloCache.evict).toHaveBeenCalledWith({
        id: apolloCache.identify(mockRunner),
      });
      expect(apolloCache.gc).toHaveBeenCalled();
    });
  });

  describe('When update fails', () => {
    describe('On a network error', () => {
      const mockErrorMsg = 'Update error!';

      beforeEach(async () => {
        runnerDeleteHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

        await clickOkAndWait();
      });

      it('error is reported to sentry', () => {
        expect(captureException).toHaveBeenCalledWith({
          error: new Error(mockErrorMsg),
          component: 'RunnerDeleteButton',
        });
      });

      it('error is shown to the user', () => {
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          title: expect.stringContaining(mockRunnerName),
          message: mockErrorMsg,
        });
      });
    });

    describe('On a validation error', () => {
      const mockErrorMsg = 'Runner not found!';
      const mockErrorMsg2 = 'User not allowed!';

      beforeEach(async () => {
        runnerDeleteHandler.mockResolvedValueOnce({
          data: {
            runnerDelete: {
              errors: [mockErrorMsg, mockErrorMsg2],
            },
          },
        });

        await clickOkAndWait();
      });

      it('error is reported to sentry', () => {
        expect(captureException).toHaveBeenCalledWith({
          error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
          component: 'RunnerDeleteButton',
        });
      });

      it('error is shown to the user', () => {
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          title: expect.stringContaining(mockRunnerName),
          message: `${mockErrorMsg} ${mockErrorMsg2}`,
        });
      });

      it('does not evict runner from apollo cache', () => {
        expect(apolloCache.evict).not.toHaveBeenCalled();
        expect(apolloCache.gc).not.toHaveBeenCalled();
      });
    });
  });

  describe('When displaying a compact button for an active runner', () => {
    beforeEach(() => {
      createComponent({
        props: {
          runner: {
            active: true,
          },
          compact: true,
        },
        mountFn: mountExtended,
      });
    });

    it('Displays no text', () => {
      expect(findBtn().text()).toBe('');
      expect(findBtn().classes('btn-icon')).toBe(true);
    });

    it('Display correctly for screen readers', () => {
      expect(findBtn().attributes('aria-label')).toBe(I18N_DELETE_RUNNER);
      expect(getTooltip()).toBe(I18N_DELETE_RUNNER);
    });

    describe('Immediately after the button is clicked', () => {
      beforeEach(() => {
        findModal().vm.$emit('primary');
      });

      it('The button has a loading state', () => {
        expect(findBtn().props('loading')).toBe(true);
      });

      it('The stale tooltip is removed', () => {
        expect(getTooltip()).toBe('');
      });
    });
  });
});
