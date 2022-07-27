import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import produce from 'immer';
import readyToMergeResponse from 'test_fixtures/graphql/merge_requests/states/ready_to_merge.query.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import readyToMergeQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/ready_to_merge.query.graphql';
import simplePoll from '~/lib/utils/simple_poll';
import CommitEdit from '~/vue_merge_request_widget/components/states/commit_edit.vue';
import CommitMessageDropdown from '~/vue_merge_request_widget/components/states/commit_message_dropdown.vue';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import SquashBeforeMerge from '~/vue_merge_request_widget/components/states/squash_before_merge.vue';
import MergeFailedPipelineConfirmationDialog from '~/vue_merge_request_widget/components/states/merge_failed_pipeline_confirmation_dialog.vue';
import { MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';

jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);
jest.mock('~/commons/nav/user_merge_requests', () => ({
  refreshUserMergeRequestCounts: jest.fn(),
}));

const commitMessage = readyToMergeResponse.data.project.mergeRequest.defaultMergeCommitMessage;
const squashCommitMessage =
  readyToMergeResponse.data.project.mergeRequest.defaultSquashCommitMessage;
const commitMessageWithDescription =
  readyToMergeResponse.data.project.mergeRequest.defaultMergeCommitMessageWithDescription;
const createTestMr = (customConfig) => {
  const mr = {
    isPipelineActive: false,
    pipeline: null,
    isPipelineFailed: false,
    isPipelinePassing: false,
    isMergeAllowed: true,
    isApproved: true,
    onlyAllowMergeIfPipelineSucceeds: false,
    ffOnlyEnabled: false,
    hasCI: false,
    ciStatus: null,
    sha: '12345678',
    squash: false,
    squashIsEnabledByDefault: false,
    squashIsReadonly: false,
    squashIsSelected: false,
    commitMessage,
    squashCommitMessage,
    commitMessageWithDescription,
    defaultMergeCommitMessage: commitMessage,
    defaultSquashCommitMessage: squashCommitMessage,
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
    targetBranch: 'main',
    preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
    availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
    mergeImmediatelyDocsPath: 'path/to/merge/immediately/docs',
    transitionStateMachine: (transition) => eventHub.$emit('StateMachineValueChanged', transition),
    translateStateToMachine: () => this.transitionStateMachine(),
    state: 'open',
    canMerge: true,
  };

  Object.assign(mr, customConfig.mr);

  return mr;
};

const createTestService = () => ({
  merge: jest.fn(),
  poll: jest.fn().mockResolvedValue(),
});

Vue.use(VueApollo);

let wrapper;
let readyToMergeResponseSpy;

const findMergeButton = () => wrapper.find('[data-testid="merge-button"]');
const findPipelineFailedConfirmModal = () =>
  wrapper.findComponent(MergeFailedPipelineConfirmationDialog);

const createReadyToMergeResponse = (customMr) => {
  return produce(readyToMergeResponse, (draft) => {
    Object.assign(draft.data.project.mergeRequest, customMr);
  });
};

const createComponent = (
  customConfig = {},
  mergeRequestWidgetGraphql = false,
  restructuredMrWidget = true,
) => {
  wrapper = shallowMount(ReadyToMerge, {
    propsData: {
      mr: createTestMr(customConfig),
      service: createTestService(),
    },
    provide: {
      glFeatures: {
        mergeRequestWidgetGraphql,
        restructuredMrWidget,
      },
    },
    stubs: {
      CommitEdit,
    },
    apolloProvider: createMockApollo([[readyToMergeQuery, readyToMergeResponseSpy]]),
  });
};

const findCheckboxElement = () => wrapper.find(SquashBeforeMerge);
const findCommitEditElements = () => wrapper.findAll(CommitEdit);
const findCommitDropdownElement = () => wrapper.find(CommitMessageDropdown);
const findFirstCommitEditLabel = () => findCommitEditElements().at(0).props('label');
const findTipLink = () => wrapper.find(GlSprintf);
const findCommitEditWithInputId = (inputId) =>
  findCommitEditElements().wrappers.find((x) => x.props('inputId') === inputId);
const findMergeCommitMessage = () => findCommitEditWithInputId('merge-message-edit').props('value');
const findSquashCommitMessage = () =>
  findCommitEditWithInputId('squash-message-edit').props('value');

const triggerApprovalUpdated = () => eventHub.$emit('ApprovalUpdated');

describe('ReadyToMerge', () => {
  beforeEach(() => {
    readyToMergeResponseSpy = jest.fn().mockResolvedValueOnce(readyToMergeResponse);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('isAutoMergeAvailable', () => {
      it('should return true when at least one merge strategy is available', () => {
        createComponent();

        expect(wrapper.vm.isAutoMergeAvailable).toBe(true);
      });

      it('should return false when no merge strategies are available', () => {
        createComponent({ mr: { availableAutoMergeStrategies: [] } });

        expect(wrapper.vm.isAutoMergeAvailable).toBe(false);
      });
    });

    describe('status', () => {
      it('defaults to success', () => {
        createComponent({ mr: { pipeline: true, availableAutoMergeStrategies: [] } });

        expect(wrapper.vm.status).toEqual('success');
      });

      it('returns failed when MR has CI but also has an unknown status', () => {
        createComponent({ mr: { hasCI: true } });

        expect(wrapper.vm.status).toEqual('failed');
      });

      it('returns default when MR has no pipeline', () => {
        createComponent({ mr: { availableAutoMergeStrategies: [] } });

        expect(wrapper.vm.status).toEqual('success');
      });

      it('returns pending when pipeline is active', () => {
        createComponent({ mr: { pipeline: {}, isPipelineActive: true } });

        expect(wrapper.vm.status).toEqual('pending');
      });

      it('returns failed when pipeline is failed', () => {
        createComponent({
          mr: { pipeline: {}, isPipelineFailed: true, availableAutoMergeStrategies: [] },
        });

        expect(wrapper.vm.status).toEqual('failed');
      });
    });

    describe('Merge Button Variant', () => {
      it('defaults to confirm class', () => {
        createComponent({
          mr: { availableAutoMergeStrategies: [] },
        });

        expect(findMergeButton().attributes('variant')).toBe('confirm');
      });
    });

    describe('status icon', () => {
      it('defaults to tick icon', () => {
        createComponent();

        expect(wrapper.vm.iconClass).toEqual('success');
      });

      it('shows tick for success status', () => {
        createComponent({ mr: { pipeline: true } });

        expect(wrapper.vm.iconClass).toEqual('success');
      });

      it('shows tick for pending status', () => {
        createComponent({ mr: { pipeline: {}, isPipelineActive: true } });

        expect(wrapper.vm.iconClass).toEqual('success');
      });
    });

    describe('mergeButtonText', () => {
      it('should return "Merge" when no auto merge strategies are available', () => {
        createComponent({ mr: { availableAutoMergeStrategies: [] } });

        expect(wrapper.vm.mergeButtonText).toEqual('Merge');
      });

      it('should return "Merge in progress"', async () => {
        createComponent();

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ isMergingImmediately: true });

        await nextTick();

        expect(wrapper.vm.mergeButtonText).toEqual('Merge in progress');
      });

      it('should return "Merge when pipeline succeeds" when the MWPS auto merge strategy is available', () => {
        createComponent({
          mr: { isMergingImmediately: false, preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY },
        });

        expect(wrapper.vm.mergeButtonText).toEqual('Merge when pipeline succeeds');
      });
    });

    describe('autoMergeText', () => {
      it('should return Merge when pipeline succeeds', () => {
        createComponent({ mr: { preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY } });

        expect(wrapper.vm.autoMergeText).toEqual('Merge when pipeline succeeds');
      });
    });

    describe('shouldShowMergeImmediatelyDropdown', () => {
      it('should return false if no pipeline is active', () => {
        createComponent({
          mr: { isPipelineActive: false, onlyAllowMergeIfPipelineSucceeds: false },
        });

        expect(wrapper.vm.shouldShowMergeImmediatelyDropdown).toBe(false);
      });

      it('should return false if "Pipelines must succeed" is enabled for the current project', () => {
        createComponent({ mr: { isPipelineActive: true, onlyAllowMergeIfPipelineSucceeds: true } });

        expect(wrapper.vm.shouldShowMergeImmediatelyDropdown).toBe(false);
      });
    });

    describe('isMergeButtonDisabled', () => {
      it('should return false with initial data', () => {
        createComponent({ mr: { isMergeAllowed: true } });

        expect(wrapper.vm.isMergeButtonDisabled).toBe(false);
      });

      it('should return true when there is no commit message', () => {
        createComponent({ mr: { isMergeAllowed: true, commitMessage: '' } });

        expect(wrapper.vm.isMergeButtonDisabled).toBe(true);
      });

      it('should return true if merge is not allowed', () => {
        createComponent({
          mr: {
            isMergeAllowed: false,
            availableAutoMergeStrategies: [],
            onlyAllowMergeIfPipelineSucceeds: true,
          },
        });

        expect(wrapper.vm.isMergeButtonDisabled).toBe(true);
      });

      it('should return true when the vm instance is making request', async () => {
        createComponent({ mr: { isMergeAllowed: true } });

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ isMakingRequest: true });

        await nextTick();

        expect(wrapper.vm.isMergeButtonDisabled).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('handleMergeButtonClick', () => {
      const response = (status) => ({
        data: {
          status,
        },
      });

      beforeEach(() => {
        readyToMergeResponseSpy = jest
          .fn()
          .mockResolvedValueOnce(createReadyToMergeResponse({ squash: true, squashOnMerge: true }))
          .mockResolvedValue(
            createReadyToMergeResponse({
              squash: true,
              squashOnMerge: true,
              defaultMergeCommitMessage: '',
              defaultSquashCommitMessage: '',
            }),
          );
      });

      it('should handle merge when pipeline succeeds', async () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest
          .spyOn(wrapper.vm.service, 'merge')
          .mockResolvedValue(response('merge_when_pipeline_succeeds'));
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ removeSourceBranch: false });

        wrapper.vm.handleMergeButtonClick(true);

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
        expect(eventHub.$emit).toHaveBeenCalledWith('StateMachineValueChanged', {
          transition: 'start-auto-merge',
        });

        const params = wrapper.vm.service.merge.mock.calls[0][0];

        expect(params).toEqual(
          expect.objectContaining({
            sha: wrapper.vm.mr.sha,
            commit_message: wrapper.vm.mr.commitMessage,
            should_remove_source_branch: false,
            auto_merge_strategy: 'merge_when_pipeline_succeeds',
          }),
        );
      });

      it('should handle merge failed', async () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'merge').mockResolvedValue(response('failed'));
        wrapper.vm.handleMergeButtonClick(false, true);

        await waitForPromises();

        expect(eventHub.$emit).toHaveBeenCalledWith('FailedToMerge', undefined);

        const params = wrapper.vm.service.merge.mock.calls[0][0];

        expect(params.should_remove_source_branch).toBeTruthy();
        expect(params.auto_merge_strategy).toBeUndefined();
      });

      it('should handle merge action accepted case', async () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'merge').mockResolvedValue(response('success'));
        jest.spyOn(wrapper.vm.mr, 'transitionStateMachine');
        wrapper.vm.handleMergeButtonClick();

        expect(eventHub.$emit).toHaveBeenCalledWith('StateMachineValueChanged', {
          transition: 'start-merge',
        });

        await waitForPromises();

        expect(wrapper.vm.mr.transitionStateMachine).toHaveBeenCalledWith({
          transition: 'start-merge',
        });

        const params = wrapper.vm.service.merge.mock.calls[0][0];

        expect(params.should_remove_source_branch).toBeTruthy();
        expect(params.auto_merge_strategy).toBeUndefined();
      });

      it('hides edit commit message', async () => {
        createComponent({}, true, true);

        await waitForPromises();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'merge').mockResolvedValue(response('success'));

        await wrapper
          .findComponent('[data-testid="widget_edit_commit_message"]')
          .vm.$emit('input', true);

        expect(wrapper.findComponent('[data-testid="edit_commit_message"]').exists()).toBe(true);

        wrapper.vm.handleMergeButtonClick();

        await waitForPromises();

        expect(wrapper.findComponent('[data-testid="edit_commit_message"]').exists()).toBe(false);
      });
    });

    describe('initiateRemoveSourceBranchPolling', () => {
      it('should emit event and call simplePoll', () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        wrapper.vm.initiateRemoveSourceBranchPolling();

        expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [true]);
        expect(simplePoll).toHaveBeenCalled();
      });
    });

    describe('handleRemoveBranchPolling', () => {
      const response = (state) => ({
        data: {
          source_branch_exists: state,
        },
      });

      it('should call start and stop polling when MR merged', async () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'poll').mockResolvedValue(response(false));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.vm.handleRemoveBranchPolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );

        await waitForPromises();

        expect(wrapper.vm.service.poll).toHaveBeenCalled();

        const args = eventHub.$emit.mock.calls[0];

        expect(args[0]).toEqual('MRWidgetUpdateRequested');
        expect(args[1]).toBeDefined();
        args[1]();

        expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [false]);

        expect(cpc).toBeFalsy();
        expect(spc).toBeTruthy();
      });

      it('should continue polling until MR is merged', async () => {
        createComponent();

        jest.spyOn(wrapper.vm.service, 'poll').mockResolvedValue(response(true));

        let cpc = false; // continuePollingCalled
        let spc = false; // stopPollingCalled

        wrapper.vm.handleRemoveBranchPolling(
          () => {
            cpc = true;
          },
          () => {
            spc = true;
          },
        );

        await waitForPromises();

        expect(cpc).toBeTruthy();
        expect(spc).toBeFalsy();
      });
    });
  });

  describe('Remove source branch checkbox', () => {
    describe('when user can merge but cannot delete branch', () => {
      it('should be disabled in the rendered output', () => {
        createComponent();

        expect(wrapper.find('#remove-source-branch-input').exists()).toBe(false);
      });
    });

    describe('when user can merge and can delete branch', () => {
      beforeEach(() => {
        createComponent({
          mr: { canRemoveSourceBranch: true },
        });
      });

      it('isRemoveSourceBranchButtonDisabled should be false', () => {
        expect(wrapper.find('#remove-source-branch-input').props('disabled')).toBe(undefined);
      });
    });
  });

  describe('render children components', () => {
    describe('squash checkbox', () => {
      it('should be rendered when squash before merge is enabled and there is more than 1 commit', () => {
        createComponent({
          mr: { commitsCount: 2, enableSquashBeforeMerge: true },
        });

        expect(findCheckboxElement().exists()).toBeTruthy();
      });

      it('should not be rendered when squash before merge is disabled', () => {
        createComponent({ mr: { commitsCount: 2, enableSquashBeforeMerge: false } });

        expect(findCheckboxElement().exists()).toBeFalsy();
      });

      it('should be rendered when there is only 1 commit', () => {
        createComponent({ mr: { commitsCount: 1, enableSquashBeforeMerge: true } });

        expect(findCheckboxElement().exists()).toBe(true);
      });

      describe('squash options', () => {
        it.each`
          squashState           | state           | prop            | expectation
          ${'squashIsReadonly'} | ${'enabled'}    | ${'isDisabled'} | ${false}
          ${'squashIsSelected'} | ${'selected'}   | ${'value'}      | ${false}
          ${'squashIsSelected'} | ${'unselected'} | ${'value'}      | ${false}
        `(
          'is $state when squashIsReadonly returns $expectation ',
          ({ squashState, prop, expectation }) => {
            createComponent({
              mr: { commitsCount: 2, enableSquashBeforeMerge: true, [squashState]: expectation },
            });

            expect(findCheckboxElement().props(prop)).toBe(expectation);
          },
        );

        it('is not rendered for "Do not allow" option', () => {
          createComponent({
            mr: {
              commitsCount: 2,
              enableSquashBeforeMerge: true,
              squashIsReadonly: true,
              squashIsSelected: false,
            },
          });

          expect(findCheckboxElement().exists()).toBe(false);
        });
      });
    });

    describe('commits edit components', () => {
      describe('when fast-forward merge is enabled', () => {
        it('should not be rendered if squash is disabled', async () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: false,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          expect(findCommitEditElements().length).toBe(0);
        });

        it('should not be rendered if squash before merge is disabled', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: true,
              enableSquashBeforeMerge: false,
              commitsCount: 2,
            },
          });

          expect(findCommitEditElements().length).toBe(0);
        });

        it('should not be rendered if there is only one commit', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: true,
              enableSquashBeforeMerge: true,
              commitsCount: 1,
            },
          });

          expect(findCommitEditElements().length).toBe(0);
        });

        it('should have one edit component if squash is enabled and there is more than 1 commit', async () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squashIsSelected: true,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

          expect(findCommitEditElements().length).toBe(1);
          expect(findFirstCommitEditLabel()).toBe('Squash commit message');
        });
      });

      it('should have two edit components when squash is enabled and there is more than 1 commit', async () => {
        createComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(findCommitEditElements().length).toBe(2);
      });

      it('should have two edit components when squash is enabled and there is more than 1 commit and mergeRequestWidgetGraphql is enabled', async () => {
        createComponent(
          {
            mr: {
              commitsCount: 2,
              squashIsSelected: true,
              enableSquashBeforeMerge: true,
            },
          },
          true,
        );

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          loading: false,
          state: {
            ...createTestMr({}),
            userPermissions: {},
            squash: true,
            mergeable: true,
            commitCount: 2,
            commitsWithoutMergeCommits: {},
          },
        });
        await nextTick();
        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(findCommitEditElements().length).toBe(2);
      });

      it('should have one edit components when squash is enabled and there is 1 commit only', async () => {
        createComponent({
          mr: {
            commitsCount: 1,
            squash: true,
            enableSquashBeforeMerge: true,
          },
        });

        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(findCommitEditElements().length).toBe(1);
      });

      it('should have correct edit squash commit label', async () => {
        createComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(findFirstCommitEditLabel()).toBe('Squash commit message');
      });
    });

    describe('commits dropdown', () => {
      it('should not be rendered if squash is disabled', () => {
        createComponent();

        expect(findCommitDropdownElement().exists()).toBeFalsy();
      });

      it('should  be rendered if squash is enabled and there is more than 1 commit', async () => {
        createComponent({
          mr: { enableSquashBeforeMerge: true, squashIsSelected: true, commitsCount: 2 },
        });

        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(findCommitDropdownElement().exists()).toBeTruthy();
      });
    });

    it('renders a tip including a link to docs on templates', async () => {
      createComponent();

      await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

      expect(findTipLink().exists()).toBe(true);
    });
  });

  describe('Merge button when pipeline has failed', () => {
    beforeEach(() => {
      createComponent({
        mr: { pipeline: {}, isPipelineFailed: true, availableAutoMergeStrategies: [] },
      });
    });

    it('should display the correct merge text', () => {
      expect(findMergeButton().text()).toBe('Merge...');
    });

    it('should display confirmation modal when merge button is clicked', async () => {
      expect(findPipelineFailedConfirmModal().props()).toEqual({ visible: false });

      await findMergeButton().vm.$emit('click');

      expect(findPipelineFailedConfirmModal().props()).toEqual({ visible: true });
    });
  });

  describe('updating graphql data triggers commit message update when default changed', () => {
    const UPDATED_MERGE_COMMIT_MESSAGE = 'New merge message from BE';
    const UPDATED_SQUASH_COMMIT_MESSAGE = 'New squash message from BE';
    const USER_COMMIT_MESSAGE = 'Merge message provided manually by user';

    const createDefaultGqlComponent = () =>
      createComponent({ mr: { commitsCount: 2, enableSquashBeforeMerge: true } }, true);

    beforeEach(() => {
      readyToMergeResponseSpy = jest
        .fn()
        .mockResolvedValueOnce(createReadyToMergeResponse({ squash: true, squashOnMerge: true }))
        .mockResolvedValue(
          createReadyToMergeResponse({
            squash: true,
            squashOnMerge: true,
            defaultMergeCommitMessage: UPDATED_MERGE_COMMIT_MESSAGE,
            defaultSquashCommitMessage: UPDATED_SQUASH_COMMIT_MESSAGE,
          }),
        );
    });

    describe.each`
      desc                       | finderFn                   | initialValue           | updatedValue                     | inputId
      ${'merge commit message'}  | ${findMergeCommitMessage}  | ${commitMessage}       | ${UPDATED_MERGE_COMMIT_MESSAGE}  | ${'#merge-message-edit'}
      ${'squash commit message'} | ${findSquashCommitMessage} | ${squashCommitMessage} | ${UPDATED_SQUASH_COMMIT_MESSAGE} | ${'#squash-message-edit'}
    `('with $desc', ({ finderFn, initialValue, updatedValue, inputId }) => {
      it('should have initial value', async () => {
        createDefaultGqlComponent();

        await waitForPromises();
        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        expect(finderFn()).toBe(initialValue);
      });

      it('should have updated value after graphql refetch', async () => {
        createDefaultGqlComponent();
        await waitForPromises();
        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        triggerApprovalUpdated();
        await waitForPromises();

        expect(finderFn()).toBe(updatedValue);
      });

      it('should not update if user has touched', async () => {
        createDefaultGqlComponent();
        await waitForPromises();
        await wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

        const input = wrapper.find(inputId);
        input.element.value = USER_COMMIT_MESSAGE;
        input.trigger('input');

        triggerApprovalUpdated();
        await waitForPromises();

        expect(finderFn()).toBe(USER_COMMIT_MESSAGE);
      });
    });
  });
});
