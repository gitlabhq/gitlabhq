import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import runnerDeleteMutation from '~/ci/runner/graphql/shared/runner_delete.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';

import RunnerDeleteAction from '~/ci/runner/components/runner_delete_action.vue';
import RunnerDeleteModal from '~/ci/runner/components/runner_delete_modal.vue';
import { allRunnersData } from '../mock_data';

const mockRunner = allRunnersData.data.runners.nodes[0];
const mockRunnerId = getIdFromGraphQLId(mockRunner.id);
const mockRunnerName = `#${mockRunnerId} (${mockRunner.shortSha})`;

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

describe('RunnerDeleteAction', () => {
  let wrapper;
  let apolloProvider;
  let apolloCache;
  let runnerDeleteHandler;
  let mockModalShow;

  const findBtn = () => wrapper.find('button');
  const findModal = () => wrapper.findComponent(RunnerDeleteModal);

  const createComponent = ({ props = {} } = {}) => {
    const { runner, ...propsData } = props;

    wrapper = shallowMountExtended(RunnerDeleteAction, {
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
      stubs: {
        RunnerDeleteModal: stubComponent(RunnerDeleteModal, {
          methods: {
            show: mockModalShow,
          },
        }),
      },
      scopedSlots: {
        default: '<button :disabled="props.loading" @click="props.onClick"/>',
      },
    });
  };

  const clickOkAndWait = async () => {
    findModal().vm.$emit('primary');
    await waitForPromises();
  };

  beforeEach(() => {
    mockModalShow = jest.fn();

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

  it('Displays an action in the slot', () => {
    expect(findBtn().exists()).toBe(true);
  });

  it('Displays a modal with the runner name', () => {
    expect(findModal().props('runnerName')).toBe(mockRunnerName);
  });

  it('Displays a modal with the runner manager count', () => {
    createComponent({
      props: {
        runner: { managers: { count: 2 } },
      },
    });

    expect(findModal().props('managersCount')).toBe(2);
  });

  it('Displays a modal when action is triggered', async () => {
    await findBtn().trigger('click');

    expect(mockModalShow).toHaveBeenCalled();
  });

  describe('Before the delete button is clicked', () => {
    it('The mutation has not been called', () => {
      expect(runnerDeleteHandler).toHaveBeenCalledTimes(0);
    });
  });

  describe('Immediately after the delete button is clicked', () => {
    beforeEach(() => {
      findModal().vm.$emit('primary');
    });

    it('The button has a loading state', () => {
      expect(findBtn().attributes('disabled')).toBe('disabled');
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
      const done = wrapper.emitted('done');

      expect(done).toHaveLength(1);
      expect(done[0][0].message).toMatch(`#${mockRunnerId}`);
      expect(done[0][0].message).toMatch(`${mockRunner.shortSha}`);
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
          component: 'RunnerDeleteAction',
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
          component: 'RunnerDeleteAction',
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
});
