import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import MergeChecksRebase from '~/vue_merge_request_widget/components/checks/rebase.vue';
import rebaseQuery from '~/vue_merge_request_widget/queries/states/rebase.query.graphql';
import eventHub from '~/vue_merge_request_widget/event_hub';
import toast from '~/vue_shared/plugins/global_toast';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/vue_shared/plugins/global_toast');

let wrapper;
const showMock = jest.fn();

const mockPipelineNodes = [
  {
    id: '1',
    project: {
      id: '2',
      fullPath: 'user/forked',
    },
  },
];

const mockQueryHandler = ({
  rebaseInProgress = false,
  targetBranch = '',
  pushToSourceBranch = true,
  nodes = mockPipelineNodes,
} = {}) =>
  jest.fn().mockResolvedValue({
    data: {
      project: {
        id: '1',
        mergeRequest: {
          id: '2',
          rebaseInProgress,
          targetBranch,
          userPermissions: {
            pushToSourceBranch,
          },
          pipelines: {
            nodes,
          },
        },
      },
    },
  });

const createMockApolloProvider = (handler) => {
  Vue.use(VueApollo);

  return createMockApollo([[rebaseQuery, handler]]);
};

function createWrapper({ propsData = {}, provideData = {}, handler = mockQueryHandler() } = {}) {
  wrapper = mountExtended(MergeChecksRebase, {
    apolloProvider: createMockApolloProvider(handler),
    provide: {
      ...provideData,
    },
    propsData: {
      mr: {},
      service: {},
      check: {
        identifier: 'need_rebase',
        status: 'FAILED',
      },
      ...propsData,
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        methods: {
          show: showMock,
        },
      }),
    },
  });
}

describe('Merge request merge checks rebase component', () => {
  const findStandardRebaseButton = () => wrapper.findByTestId('standard-rebase-button');
  const findRebaseWithoutCiButton = () => wrapper.findByTestId('rebase-without-ci-button');
  const findModal = () => wrapper.findComponent(GlModal);

  describe('with permissions', () => {
    const rebaseMock = jest.fn().mockResolvedValue();
    const pollMock = jest.fn().mockResolvedValue({});

    describe('Rebase buttons', () => {
      it('renders both buttons', async () => {
        createWrapper({
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();

        expect(findRebaseWithoutCiButton().exists()).toBe(true);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        createWrapper({
          propsData: {
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();

        findStandardRebaseButton().vm.$emit('click');

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });

      it('starts the CI-skipping rebase when clicking on "Rebase without CI"', async () => {
        createWrapper({
          propsData: {
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();

        findRebaseWithoutCiButton().vm.$emit('click');

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: true });
      });
    });

    describe('Rebase when pipelines must succeed is enabled', () => {
      beforeEach(async () => {
        createWrapper({
          propsData: {
            mr: {
              onlyAllowMergeIfPipelineSucceeds: true,
            },
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();
      });

      it('renders only the rebase button', () => {
        expect(findRebaseWithoutCiButton().exists()).toBe(false);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        findStandardRebaseButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });
    });

    describe('Rebase when pipelines must succeed and skipped pipelines are considered successful are enabled', () => {
      beforeEach(async () => {
        createWrapper({
          propsData: {
            mr: {
              onlyAllowMergeIfPipelineSucceeds: true,
              allowMergeOnSkippedPipeline: true,
            },
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();
      });

      it('renders both rebase buttons', () => {
        expect(findRebaseWithoutCiButton().exists()).toBe(true);
        expect(findStandardRebaseButton().exists()).toBe(true);
      });

      it('starts the rebase when clicking', async () => {
        findStandardRebaseButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: false });
      });

      it('starts the CI-skipping rebase when clicking on "Rebase without CI"', async () => {
        findRebaseWithoutCiButton().vm.$emit('click');

        await nextTick();

        expect(rebaseMock).toHaveBeenCalledWith({ skipCi: true });
      });
    });

    describe('security modal', () => {
      it('displays modal and rebases after confirming', async () => {
        createWrapper({
          propsData: {
            mr: {
              sourceProjectFullPath: 'user/forked',
              targetProjectFullPath: 'root/original',
            },
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          provideData: { canCreatePipelineInTargetProject: true },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();

        findStandardRebaseButton().vm.$emit('click');
        expect(showMock).toHaveBeenCalled();

        findModal().vm.$emit('primary');

        expect(rebaseMock).toHaveBeenCalled();
      });

      it('does not display modal', async () => {
        createWrapper({
          propsData: {
            mr: {
              sourceProjectFullPath: 'user/forked',
              targetProjectFullPath: 'root/original',
            },
            service: {
              rebase: rebaseMock,
              poll: pollMock,
            },
          },
          provideData: { canCreatePipelineInTargetProject: false },
          handler: mockQueryHandler({ pushToSourceBranch: true }),
        });

        await waitForPromises();

        findStandardRebaseButton().vm.$emit('click');

        expect(showMock).not.toHaveBeenCalled();
        expect(rebaseMock).toHaveBeenCalled();
      });
    });
  });

  describe('without permissions', () => {
    const exampleTargetBranch = 'fake-branch-to-test-with';

    it('does render the "Rebase without pipeline" button', async () => {
      createWrapper({
        handler: mockQueryHandler({
          rebaseInProgress: false,
          pushToSourceBranch: false,
          targetBranch: exampleTargetBranch,
        }),
      });

      await waitForPromises();

      expect(findRebaseWithoutCiButton().exists()).toBe(false);
    });
  });

  describe('methods', () => {
    it('checkRebaseStatus', async () => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      createWrapper({
        propsData: {
          service: {
            rebase() {
              return Promise.resolve();
            },
            poll() {
              return Promise.resolve({
                data: {
                  rebase_in_progress: false,
                  should_be_rebased: false,
                  merge_error: null,
                },
              });
            },
          },
        },
      });

      await waitForPromises();

      findRebaseWithoutCiButton().vm.$emit('click');

      // Wait for the rebase request
      await nextTick();
      // Wait for the polling request
      await nextTick();
      // Wait for the eventHub to be called
      await nextTick();

      expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetRebaseSuccess');
      expect(toast).toHaveBeenCalledWith('Rebase completed');
    });
  });

  describe('error states', () => {
    it('does not render action buttons', async () => {
      createWrapper({
        handler: jest.fn().mockResolvedValue({ data: { project: null } }),
      });

      await waitForPromises();

      expect(findStandardRebaseButton().exists()).toBe(false);
      expect(findRebaseWithoutCiButton().exists()).toBe(false);
    });
  });
});
