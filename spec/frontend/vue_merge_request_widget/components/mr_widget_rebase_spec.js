import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import WidgetRebase from '~/vue_merge_request_widget/components/states/mr_widget_rebase.vue';
import rebaseQuery from '~/vue_merge_request_widget/queries/states/rebase.query.graphql';
import eventHub from '~/vue_merge_request_widget/event_hub';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import toast from '~/vue_shared/plugins/global_toast';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
  pushToSourceBranch = false,
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
  wrapper = shallowMountExtended(WidgetRebase, {
    apolloProvider: createMockApolloProvider(handler),
    provide: {
      ...provideData,
    },
    propsData: {
      mr: {},
      service: {},
      ...propsData,
    },
    stubs: {
      StateContainer,
      GlModal: stubComponent(GlModal, {
        methods: {
          show: showMock,
        },
      }),
    },
  });
}

describe('Merge request widget rebase component', () => {
  const findRebaseMessage = () => wrapper.findByTestId('rebase-message');
  const findBoldText = () => wrapper.findComponent(BoldText);
  const findRebaseMessageText = () => findRebaseMessage().text();
  const findStandardRebaseButton = () => wrapper.findByTestId('standard-rebase-button');
  const findRebaseWithoutCiButton = () => wrapper.findByTestId('rebase-without-ci-button');
  const findModal = () => wrapper.findComponent(GlModal);

  describe('while rebasing', () => {
    it('should show progress message', async () => {
      createWrapper({
        handler: mockQueryHandler({ rebaseInProgress: true }),
      });

      await waitForPromises();

      expect(findRebaseMessageText()).toContain('Rebase in progress');
    });
  });

  describe('with permissions', () => {
    const rebaseMock = jest.fn().mockResolvedValue();
    const pollMock = jest.fn().mockResolvedValue({});

    it('renders the warning message', async () => {
      createWrapper({
        handler: mockQueryHandler({
          rebaseInProgress: false,
          pushToSourceBranch: false,
        }),
      });

      await waitForPromises();

      expect(findBoldText().props('message')).toContain('Merge blocked');
      expect(findBoldText().props('message').replace(/\s\s+/g, ' ')).toContain(
        'the source branch must be rebased onto the target branch',
      );
    });

    it('renders an error message when rebasing has failed', async () => {
      createWrapper({
        propsData: {
          service: {
            rebase: jest.fn().mockRejectedValue({
              response: {
                data: {
                  merge_error: 'Something went wrong!',
                },
              },
            }),
          },
        },
        handler: mockQueryHandler({ pushToSourceBranch: true }),
      });
      await waitForPromises();

      findStandardRebaseButton().vm.$emit('click');

      await waitForPromises();
      expect(findRebaseMessageText()).toContain('Something went wrong!');
    });

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

    describe('UI text', () => {
      beforeEach(async () => {
        createWrapper({
          handler: mockQueryHandler({
            pushToSourceBranch: false,
            targetBranch: exampleTargetBranch,
          }),
        });

        await waitForPromises();
      });

      it('renders a message explaining user does not have permissions', () => {
        expect(findBoldText().props('message')).toContain('Merge blocked');
        expect(findBoldText().props('message')).toContain('the source branch must be rebased');
      });

      it('renders the correct target branch name', () => {
        expect(findBoldText().props('message')).toContain('Merge blocked:');
        expect(findBoldText().props('message')).toContain(
          'the source branch must be rebased onto the target branch.',
        );
      });
    });

    it('does render the "Rebase without pipeline" button', async () => {
      createWrapper({
        handler: mockQueryHandler({
          rebaseInProgress: false,
          pushToSourceBranch: false,
          targetBranch: exampleTargetBranch,
        }),
      });

      await waitForPromises();

      expect(findRebaseWithoutCiButton().exists()).toBe(true);
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

  // This may happen when the session of a user is expired.
  // see https://gitlab.com/gitlab-org/gitlab/-/issues/413627
  describe('with empty project', () => {
    it('does not throw any error', async () => {
      const fn = async () => {
        createWrapper({
          handler: jest.fn().mockResolvedValue({ data: { project: null } }),
        });

        await waitForPromises();
      };

      await expect(fn()).resolves.not.toThrow();
    });
  });
});
