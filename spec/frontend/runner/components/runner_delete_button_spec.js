import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import runnerDeleteMutation from '~/runner/graphql/shared/runner_delete.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/flash';
import { I18N_DELETE_RUNNER } from '~/runner/constants';

import RunnerDeleteButton from '~/runner/components/runner_delete_button.vue';
import RunnerDeleteModal from '~/runner/components/runner_delete_modal.vue';
import { runnersData } from '../mock_data';

const mockRunner = runnersData.data.runners.nodes[0];
const mockRunnerId = getIdFromGraphQLId(mockRunner.id);

Vue.use(VueApollo);

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

describe('RunnerDeleteButton', () => {
  let wrapper;
  let runnerDeleteHandler;

  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;
  const getModal = () => getBinding(wrapper.element, 'gl-modal').value;
  const findBtn = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(RunnerDeleteModal);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    const { runner, ...propsData } = props;

    wrapper = mountFn(RunnerDeleteButton, {
      propsData: {
        runner: {
          id: mockRunner.id,
          shortSha: mockRunner.shortSha,
          ...runner,
        },
        ...propsData,
      },
      apolloProvider: createMockApollo([[runnerDeleteMutation, runnerDeleteHandler]]),
      directives: {
        GlTooltip: createMockDirective(),
        GlModal: createMockDirective(),
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

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
    expect(findModal().props('runnerName')).toBe(`#${mockRunnerId} (${mockRunner.shortSha})`);
  });

  it('Displays a modal when clicked', () => {
    const modalId = `delete-runner-modal-${mockRunnerId}`;

    expect(getModal()).toBe(modalId);
    expect(findModal().attributes('modal-id')).toBe(modalId);
  });

  it('Does not display redundant text for screen readers', () => {
    expect(findBtn().attributes('aria-label')).toBe(undefined);
  });

  describe(`Before the delete button is clicked`, () => {
    it('The mutation has not been called', () => {
      expect(runnerDeleteHandler).toHaveBeenCalledTimes(0);
    });
  });

  describe('Immediately after the delete button is clicked', () => {
    beforeEach(async () => {
      findModal().vm.$emit('primary');
    });

    it('The button has a loading state', async () => {
      expect(findBtn().props('loading')).toBe(true);
    });

    it('The stale tooltip is removed', async () => {
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
      beforeEach(async () => {
        findModal().vm.$emit('primary');
      });

      it('The button has a loading state', async () => {
        expect(findBtn().props('loading')).toBe(true);
      });

      it('The stale tooltip is removed', async () => {
        expect(getTooltip()).toBe('');
      });
    });
  });
});
