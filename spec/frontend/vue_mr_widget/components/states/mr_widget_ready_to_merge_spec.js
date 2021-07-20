import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import simplePoll from '~/lib/utils/simple_poll';
import CommitEdit from '~/vue_merge_request_widget/components/states/commit_edit.vue';
import CommitMessageDropdown from '~/vue_merge_request_widget/components/states/commit_message_dropdown.vue';
import CommitsHeader from '~/vue_merge_request_widget/components/states/commits_header.vue';
import ReadyToMerge from '~/vue_merge_request_widget/components/states/ready_to_merge.vue';
import SquashBeforeMerge from '~/vue_merge_request_widget/components/states/squash_before_merge.vue';
import { MWPS_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import eventHub from '~/vue_merge_request_widget/event_hub';

jest.mock('~/lib/utils/simple_poll', () =>
  jest.fn().mockImplementation(jest.requireActual('~/lib/utils/simple_poll').default),
);
jest.mock('~/commons/nav/user_merge_requests', () => ({
  refreshUserMergeRequestCounts: jest.fn(),
}));

const commitMessage = 'This is the commit message';
const squashCommitMessage = 'This is the squash commit message';
const commitMessageWithDescription = 'This is the commit message description';
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
    shouldRemoveSourceBranch: true,
    canRemoveSourceBranch: false,
    targetBranch: 'main',
    preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY,
    availableAutoMergeStrategies: [MWPS_MERGE_STRATEGY],
    mergeImmediatelyDocsPath: 'path/to/merge/immediately/docs',
  };

  Object.assign(mr, customConfig.mr);

  return mr;
};

const createTestService = () => ({
  merge: jest.fn(),
  poll: jest.fn().mockResolvedValue(),
});

let wrapper;
const createComponent = (customConfig = {}, mergeRequestWidgetGraphql = false) => {
  wrapper = shallowMount(ReadyToMerge, {
    propsData: {
      mr: createTestMr(customConfig),
      service: createTestService(),
    },
    provide: {
      glFeatures: {
        mergeRequestWidgetGraphql,
      },
    },
    stubs: {
      CommitEdit,
    },
  });
};

describe('ReadyToMerge', () => {
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

    describe('mergeButtonVariant', () => {
      it('defaults to confirm class', () => {
        createComponent({
          mr: { availableAutoMergeStrategies: [] },
        });

        expect(wrapper.vm.mergeButtonVariant).toEqual('confirm');
      });

      it('returns confirm class for success status', () => {
        createComponent({
          mr: { availableAutoMergeStrategies: [], pipeline: true },
        });

        expect(wrapper.vm.mergeButtonVariant).toEqual('confirm');
      });

      it('returns confirm class for pending status', () => {
        createComponent();

        expect(wrapper.vm.mergeButtonVariant).toEqual('confirm');
      });

      it('returns danger class for failed status', () => {
        createComponent({ mr: { hasCI: true } });

        expect(wrapper.vm.mergeButtonVariant).toEqual('danger');
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

        wrapper.setData({ isMergingImmediately: true });

        await Vue.nextTick();

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

        wrapper.setData({ isMakingRequest: true });

        await Vue.nextTick();

        expect(wrapper.vm.isMergeButtonDisabled).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('updateMergeCommitMessage', () => {
      it('should revert flag and change commitMessage', () => {
        createComponent();

        wrapper.vm.updateMergeCommitMessage(true);

        expect(wrapper.vm.commitMessage).toEqual(commitMessageWithDescription);
        wrapper.vm.updateMergeCommitMessage(false);

        expect(wrapper.vm.commitMessage).toEqual(commitMessage);
      });
    });

    describe('handleMergeButtonClick', () => {
      const returnPromise = (status) =>
        new Promise((resolve) => {
          resolve({
            data: {
              status,
            },
          });
        });

      it('should handle merge when pipeline succeeds', (done) => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest
          .spyOn(wrapper.vm.service, 'merge')
          .mockReturnValue(returnPromise('merge_when_pipeline_succeeds'));
        wrapper.setData({ removeSourceBranch: false });

        wrapper.vm.handleMergeButtonClick(true);

        setImmediate(() => {
          expect(wrapper.vm.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');

          const params = wrapper.vm.service.merge.mock.calls[0][0];

          expect(params).toEqual(
            expect.objectContaining({
              sha: wrapper.vm.mr.sha,
              commit_message: wrapper.vm.mr.commitMessage,
              should_remove_source_branch: false,
              auto_merge_strategy: 'merge_when_pipeline_succeeds',
            }),
          );
          done();
        });
      });

      it('should handle merge failed', (done) => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'merge').mockReturnValue(returnPromise('failed'));
        wrapper.vm.handleMergeButtonClick(false, true);

        setImmediate(() => {
          expect(wrapper.vm.isMakingRequest).toBeTruthy();
          expect(eventHub.$emit).toHaveBeenCalledWith('FailedToMerge', undefined);

          const params = wrapper.vm.service.merge.mock.calls[0][0];

          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.auto_merge_strategy).toBeUndefined();
          done();
        });
      });

      it('should handle merge action accepted case', (done) => {
        createComponent();

        jest.spyOn(wrapper.vm.service, 'merge').mockReturnValue(returnPromise('success'));
        jest.spyOn(wrapper.vm, 'initiateMergePolling').mockImplementation(() => {});
        wrapper.vm.handleMergeButtonClick();

        setImmediate(() => {
          expect(wrapper.vm.isMakingRequest).toBeTruthy();
          expect(wrapper.vm.initiateMergePolling).toHaveBeenCalled();

          const params = wrapper.vm.service.merge.mock.calls[0][0];

          expect(params.should_remove_source_branch).toBeTruthy();
          expect(params.auto_merge_strategy).toBeUndefined();
          done();
        });
      });
    });

    describe('initiateMergePolling', () => {
      it('should call simplePoll', () => {
        createComponent();

        wrapper.vm.initiateMergePolling();

        expect(simplePoll).toHaveBeenCalledWith(expect.any(Function), { timeout: 0 });
      });

      it('should call handleMergePolling', () => {
        createComponent();

        jest.spyOn(wrapper.vm, 'handleMergePolling').mockImplementation(() => {});

        wrapper.vm.initiateMergePolling();

        expect(wrapper.vm.handleMergePolling).toHaveBeenCalled();
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
      const returnPromise = (state) =>
        new Promise((resolve) => {
          resolve({
            data: {
              source_branch_exists: state,
            },
          });
        });

      it('should call start and stop polling when MR merged', (done) => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        jest.spyOn(wrapper.vm.service, 'poll').mockReturnValue(returnPromise(false));

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
        setImmediate(() => {
          expect(wrapper.vm.service.poll).toHaveBeenCalled();

          const args = eventHub.$emit.mock.calls[0];

          expect(args[0]).toEqual('MRWidgetUpdateRequested');
          expect(args[1]).toBeDefined();
          args[1]();

          expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [false]);

          expect(cpc).toBeFalsy();
          expect(spc).toBeTruthy();

          done();
        });
      });

      it('should continue polling until MR is merged', (done) => {
        createComponent();

        jest.spyOn(wrapper.vm.service, 'poll').mockReturnValue(returnPromise(true));

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
        setImmediate(() => {
          expect(cpc).toBeTruthy();
          expect(spc).toBeFalsy();

          done();
        });
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
    const findCheckboxElement = () => wrapper.find(SquashBeforeMerge);
    const findCommitsHeaderElement = () => wrapper.find(CommitsHeader);
    const findCommitEditElements = () => wrapper.findAll(CommitEdit);
    const findCommitDropdownElement = () => wrapper.find(CommitMessageDropdown);
    const findFirstCommitEditLabel = () => findCommitEditElements().at(0).props('label');

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

      it('should not be rendered when there is only 1 commit', () => {
        createComponent({ mr: { commitsCount: 1, enableSquashBeforeMerge: true } });

        expect(findCheckboxElement().exists()).toBeFalsy();
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

    describe('commits count collapsible header', () => {
      it('should be rendered when fast-forward is disabled', () => {
        createComponent();

        expect(findCommitsHeaderElement().exists()).toBeTruthy();
      });

      describe('when fast-forward is enabled', () => {
        it('should be rendered if squash and squash before are enabled and there is more than 1 commit', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              enableSquashBeforeMerge: true,
              squashIsSelected: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeTruthy();
        });

        it('should not be rendered if squash before merge is disabled', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              enableSquashBeforeMerge: false,
              squash: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });

        it('should not be rendered if squash is disabled', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: false,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });

        it('should not be rendered if commits count is 1', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: true,
              enableSquashBeforeMerge: true,
              commitsCount: 1,
            },
          });

          expect(findCommitsHeaderElement().exists()).toBeFalsy();
        });
      });
    });

    describe('commits edit components', () => {
      describe('when fast-forward merge is enabled', () => {
        it('should not be rendered if squash is disabled', () => {
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

        it('should have one edit component if squash is enabled and there is more than 1 commit', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squashIsSelected: true,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          expect(findCommitEditElements().length).toBe(1);
          expect(findFirstCommitEditLabel()).toBe('Squash commit message');
        });
      });

      it('should have one edit component when squash is disabled', () => {
        createComponent();

        expect(findCommitEditElements().length).toBe(1);
      });

      it('should have two edit components when squash is enabled and there is more than 1 commit', () => {
        createComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

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
        await wrapper.vm.$nextTick();

        expect(findCommitEditElements().length).toBe(2);
      });

      it('should have one edit components when squash is enabled and there is 1 commit only', () => {
        createComponent({
          mr: {
            commitsCount: 1,
            squash: true,
            enableSquashBeforeMerge: true,
          },
        });

        expect(findCommitEditElements().length).toBe(1);
      });

      it('should have correct edit merge commit label', () => {
        createComponent();

        expect(findFirstCommitEditLabel()).toBe('Merge commit message');
      });

      it('should have correct edit squash commit label', () => {
        createComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        expect(findFirstCommitEditLabel()).toBe('Squash commit message');
      });
    });

    describe('commits dropdown', () => {
      it('should not be rendered if squash is disabled', () => {
        createComponent();

        expect(findCommitDropdownElement().exists()).toBeFalsy();
      });

      it('should  be rendered if squash is enabled and there is more than 1 commit', () => {
        createComponent({
          mr: { enableSquashBeforeMerge: true, squashIsSelected: true, commitsCount: 2 },
        });

        expect(findCommitDropdownElement().exists()).toBeTruthy();
      });
    });
  });

  describe('Merge request project settings', () => {
    describe('when the merge commit merge method is enabled', () => {
      beforeEach(() => {
        createComponent({
          mr: { ffOnlyEnabled: false },
        });
      });

      it('should not show fast forward message', () => {
        expect(wrapper.find('.mr-fast-forward-message').exists()).toBe(false);
      });
    });

    describe('when the fast-forward merge method is enabled', () => {
      beforeEach(() => {
        createComponent({
          mr: { ffOnlyEnabled: true },
        });
      });

      it('should show fast forward message', () => {
        expect(wrapper.find('.mr-fast-forward-message').exists()).toBe(true);
      });
    });
  });

  describe('with a mismatched SHA', () => {
    const findMismatchShaBlock = () => wrapper.find('.js-sha-mismatch');
    const findMismatchShaTextBlock = () => findMismatchShaBlock().find(GlSprintf);

    beforeEach(() => {
      createComponent({
        mr: {
          isSHAMismatch: true,
          mergeRequestDiffsPath: '/merge_requests/1/diffs',
        },
      });
    });

    it('displays a warning message', () => {
      expect(findMismatchShaBlock().exists()).toBe(true);
    });

    it('warns the user to refresh to review', () => {
      expect(findMismatchShaTextBlock().element.outerHTML).toMatchSnapshot();
    });
  });
});
