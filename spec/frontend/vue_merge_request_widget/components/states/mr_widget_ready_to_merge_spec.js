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
    mergeable: true,
    userPermissions: {
      removeSourceBranch: true,
      canMerge: true,
    },
  };

  Object.assign(mr, customConfig.mr);

  return mr;
};

const createTestService = () => ({
  merge: jest.fn().mockResolvedValue(),
  poll: jest.fn().mockResolvedValue(),
});

Vue.use(VueApollo);

let service;
let wrapper;
let readyToMergeResponseSpy;

const createReadyToMergeResponse = (customMr) => {
  return produce(readyToMergeResponse, (draft) => {
    Object.assign(draft.data.project.mergeRequest, customMr);
  });
};

const createComponent = (customConfig = {}, createState = true) => {
  wrapper = shallowMount(ReadyToMerge, {
    propsData: {
      mr: createTestMr(customConfig),
      service,
    },
    data() {
      if (createState) {
        return {
          loading: false,
          state: {
            ...createTestMr(customConfig),
          },
        };
      }
      return {
        loading: true,
      };
    },
    stubs: {
      CommitEdit,
      GlSprintf,
    },
    apolloProvider: createMockApollo([[readyToMergeQuery, readyToMergeResponseSpy]]),
    provide: {
      glFeatures: {
        autoMergeLabelsMrWidget: false,
      },
    },
  });
};

const findMergeButton = () => wrapper.find('[data-testid="merge-button"]');
const findMergeImmediatelyDropdown = () =>
  wrapper.find('[data-testid="merge-immediately-dropdown"');
const findSourceBranchDeletedText = () =>
  wrapper.find('[data-testid="source-branch-deleted-text"]');
const findPipelineFailedConfirmModal = () =>
  wrapper.findComponent(MergeFailedPipelineConfirmationDialog);
const findCheckboxElement = () => wrapper.findComponent(SquashBeforeMerge);
const findCommitEditElements = () => wrapper.findAllComponents(CommitEdit);
const findCommitDropdownElement = () => wrapper.findComponent(CommitMessageDropdown);
const findFirstCommitEditLabel = () => findCommitEditElements().at(0).props('label');
const findTipLink = () => wrapper.findComponent(GlSprintf);
const findCommitEditWithInputId = (inputId) =>
  findCommitEditElements().wrappers.find((x) => x.props('inputId') === inputId);
const findMergeCommitMessage = () => findCommitEditWithInputId('merge-message-edit').props('value');
const findSquashCommitMessage = () =>
  findCommitEditWithInputId('squash-message-edit').props('value');
const findDeleteSourceBranchCheckbox = () =>
  wrapper.find('[data-testid="delete-source-branch-checkbox"]');

const triggerApprovalUpdated = () => eventHub.$emit('ApprovalUpdated');
const triggerEditCommitInput = () =>
  wrapper.find('[data-testid="widget_edit_commit_message"]').vm.$emit('input', true);

describe('ReadyToMerge', () => {
  beforeEach(() => {
    service = createTestService();
    readyToMergeResponseSpy = jest.fn().mockResolvedValueOnce(readyToMergeResponse);
  });

  describe('computed', () => {
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
        createComponent({ mr: { pipeline: { active: true }, isPipelineActive: true } });

        expect(wrapper.vm.status).toEqual('pending');
      });

      it('returns failed when pipeline is failed', () => {
        createComponent({
          mr: { pipeline: { status: 'FAILED' }, availableAutoMergeStrategies: [], hasCI: true },
        });

        expect(wrapper.vm.status).toEqual('failed');
      });
    });

    describe('status icon', () => {
      it('defaults to tick icon', () => {
        createComponent({ mr: { mergeable: true } });

        expect(wrapper.vm.iconClass).toEqual('success');
      });

      it('shows tick for success status', () => {
        createComponent({ mr: { pipeline: { status: 'SUCCESS' }, mergeable: true } });

        expect(wrapper.vm.iconClass).toEqual('success');
      });

      it('shows tick for pending status', () => {
        createComponent({ mr: { pipeline: { active: true }, mergeable: true } });

        expect(wrapper.vm.iconClass).toEqual('success');
      });
    });
  });

  describe('merge button text', () => {
    it('should return "Merge" when no auto merge strategies are available', () => {
      createComponent({ mr: { availableAutoMergeStrategies: [] } });

      expect(findMergeButton().text()).toBe('Merge');
    });

    it('should return "Merge when pipeline succeeds" when the MWPS auto merge strategy is available', () => {
      createComponent({
        mr: { preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY },
      });

      expect(findMergeButton().text()).toBe('Merge when pipeline succeeds');
    });

    it('should return Merge when pipeline succeeds', () => {
      createComponent({ mr: { preferredAutoMergeStrategy: MWPS_MERGE_STRATEGY } });

      expect(findMergeButton().text()).toBe('Merge when pipeline succeeds');
    });
  });

  describe('merge immediately dropdown', () => {
    it('dropdown should be hidden if no pipeline is active', () => {
      createComponent({
        mr: { isPipelineActive: false, onlyAllowMergeIfPipelineSucceeds: false },
      });

      expect(findMergeImmediatelyDropdown().exists()).toBe(false);
    });

    it('dropdown should be hidden if "Pipelines must succeed" is enabled', () => {
      createComponent({ mr: { isPipelineActive: true, onlyAllowMergeIfPipelineSucceeds: true } });

      expect(findMergeImmediatelyDropdown().exists()).toBe(false);
    });
  });

  describe('merge button disabled state', () => {
    it('should not be disabled initally', () => {
      createComponent();

      expect(findMergeButton().props('disabled')).toBe(false);
    });

    it('should be disabled when there is no commit message', () => {
      createComponent({ mr: { commitMessage: '' } });

      expect(findMergeButton().props('disabled')).toBe(true);
    });

    it('should be disabled if merge is not allowed', () => {
      createComponent({ mr: { preventMerge: true } });

      expect(findMergeButton().props('disabled')).toBe(true);
    });

    it('should be disabled when making request', async () => {
      createComponent({ mr: { isMergeAllowed: true } }, true);

      findMergeButton().vm.$emit('click');

      await nextTick();

      expect(findMergeButton().props('disabled')).toBe(true);
    });
  });

  describe('sourceBranchDeletedText', () => {
    const should = 'Source branch will be deleted.';
    const shouldNot = 'Source branch will not be deleted.';
    const did = 'Deleted the source branch.';
    const didNot = 'Did not delete the source branch.';
    const scenarios = [
      "the MR hasn't merged yet, and the backend-provided value expects to delete the branch",
      "the MR hasn't merged yet, and the backend-provided value expects to leave the branch",
      "the MR hasn't merged yet, and the backend-provided value is a non-boolean falsey value",
      "the MR hasn't merged yet, and the backend-provided value is a non-boolean truthy value",
      'the MR has been merged, and the backend reports that the branch has been removed',
      'the MR has been merged, and the backend reports that the branch has not been removed',
      'the MR has been merged, and the backend reports a non-boolean falsey value',
      'the MR has been merged, and the backend reports a non-boolean truthy value',
    ];

    it.each`
      describe        | premerge | mrShould  | mrRemoved | output
      ${scenarios[0]} | ${true}  | ${true}   | ${null}   | ${should}
      ${scenarios[1]} | ${true}  | ${false}  | ${null}   | ${shouldNot}
      ${scenarios[2]} | ${true}  | ${null}   | ${null}   | ${shouldNot}
      ${scenarios[3]} | ${true}  | ${'yeah'} | ${null}   | ${should}
      ${scenarios[4]} | ${false} | ${null}   | ${true}   | ${did}
      ${scenarios[5]} | ${false} | ${null}   | ${false}  | ${didNot}
      ${scenarios[6]} | ${false} | ${null}   | ${null}   | ${didNot}
      ${scenarios[7]} | ${false} | ${null}   | ${'yep'}  | ${did}
    `(
      'in the case that $describe, returns "$output"',
      ({ premerge, mrShould, mrRemoved, output }) => {
        createComponent({
          mr: {
            state: !premerge ? 'merged' : 'literally-anything-else',
            shouldRemoveSourceBranch: mrShould,
            sourceBranchRemoved: mrRemoved,
            autoMergeEnabled: true,
          },
        });

        expect(findSourceBranchDeletedText().text()).toBe(output);
      },
    );
  });

  describe('Merge Button Variant', () => {
    it('defaults to confirm class', () => {
      createComponent({
        mr: { availableAutoMergeStrategies: [], mergeable: true },
      });

      expect(findMergeButton().attributes('variant')).toBe('confirm');
    });
  });

  describe('Merge button click', () => {
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
      createComponent({ mr: { shouldRemoveSourceBranch: false } }, true);

      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      jest.spyOn(service, 'merge').mockResolvedValue(response('merge_when_pipeline_succeeds'));

      findMergeButton().vm.$emit('click');

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
      expect(eventHub.$emit).toHaveBeenCalledWith('StateMachineValueChanged', {
        transition: 'start-auto-merge',
      });

      const params = service.merge.mock.calls[0][0];

      expect(params).toEqual(
        expect.objectContaining({
          sha: '12345678',
          commit_message: commitMessage,
          should_remove_source_branch: false,
          auto_merge_strategy: 'merge_when_pipeline_succeeds',
        }),
      );
    });

    it('should handle merge failed', async () => {
      createComponent({ mr: { availableAutoMergeStrategies: [] } });

      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      jest.spyOn(service, 'merge').mockResolvedValue(response('failed'));

      findMergeButton().vm.$emit('click');

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith('FailedToMerge', undefined);

      const params = service.merge.mock.calls[0][0];

      expect(params.should_remove_source_branch).toBe(true);
      expect(params.auto_merge_strategy).toBeUndefined();
    });

    it('should handle merge action accepted case', async () => {
      createComponent({ mr: { availableAutoMergeStrategies: [] } });

      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      jest.spyOn(service, 'merge').mockResolvedValue(response('success'));
      jest.spyOn(wrapper.vm.mr, 'transitionStateMachine');

      findMergeButton().vm.$emit('click');

      expect(eventHub.$emit).toHaveBeenCalledWith('StateMachineValueChanged', {
        transition: 'start-merge',
      });

      await waitForPromises();

      expect(wrapper.vm.mr.transitionStateMachine).toHaveBeenCalledWith({
        transition: 'start-merge',
      });

      const params = service.merge.mock.calls[0][0];

      expect(params.should_remove_source_branch).toBe(true);
      expect(params.auto_merge_strategy).toBeUndefined();
    });

    it('hides edit commit message', async () => {
      createComponent();

      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
      jest.spyOn(service, 'merge').mockResolvedValue(response('success'));

      await triggerEditCommitInput();

      expect(wrapper.findComponent('[data-testid="edit_commit_message"]').exists()).toBe(true);

      findMergeButton().vm.$emit('click');

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
      jest.spyOn(service, 'poll').mockResolvedValue(response(false));

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

      expect(service.poll).toHaveBeenCalled();

      const args = eventHub.$emit.mock.calls[0];

      expect(args[0]).toEqual('MRWidgetUpdateRequested');
      expect(args[1]).toBeDefined();
      args[1]();

      expect(eventHub.$emit).toHaveBeenCalledWith('SetBranchRemoveFlag', [false]);

      expect(cpc).toBe(false);
      expect(spc).toBe(true);
    });

    it('should continue polling until MR is merged', async () => {
      createComponent();

      jest.spyOn(service, 'poll').mockResolvedValue(response(true));

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

      expect(cpc).toBe(true);
      expect(spc).toBe(false);
    });
  });

  describe('Remove source branch checkbox', () => {
    describe('when user can merge but cannot delete branch', () => {
      it('should be disabled in the rendered output', () => {
        createComponent({
          mr: {
            mergeable: true,
            userPermissions: {
              removeSourceBranch: false,
              canMerge: true,
            },
          },
        });

        expect(findDeleteSourceBranchCheckbox().exists()).toBe(false);
      });
    });

    describe('when user can merge and can delete branch', () => {
      beforeEach(() => {
        createComponent({
          mr: { canRemoveSourceBranch: true, mergeable: true },
        });
      });

      it('isRemoveSourceBranchButtonDisabled should be false', () => {
        expect(findDeleteSourceBranchCheckbox().props('disabled')).toBe(undefined);
      });
    });
  });

  describe('render children components', () => {
    describe('squash checkbox', () => {
      it('should be rendered when squash before merge is enabled and there is more than 1 commit', () => {
        createComponent({
          mr: { commitsCount: 2, enableSquashBeforeMerge: true, mergeable: true },
        });

        expect(findCheckboxElement().exists()).toBe(true);
      });

      it('should not be rendered when squash before merge is disabled', () => {
        createComponent({ mr: { commitsCount: 2, enableSquashBeforeMerge: false } });

        expect(findCheckboxElement().exists()).toBe(false);
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
          'is $state when squashIsReadonly returns $expectation',
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
        it('should not be rendered if squash is disabled', () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squash: false,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
            },
          });

          expect(findCommitEditElements()).toHaveLength(0);
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

          expect(findCommitEditElements()).toHaveLength(0);
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

          expect(findCommitEditElements()).toHaveLength(0);
        });

        it('should have one edit component if squash is enabled and there is more than 1 commit', async () => {
          createComponent({
            mr: {
              ffOnlyEnabled: true,
              squashIsSelected: true,
              enableSquashBeforeMerge: true,
              commitsCount: 2,
              mergeRequestsFfOnlyEnabled: true,
            },
          });

          await triggerEditCommitInput();

          expect(findCommitEditElements()).toHaveLength(1);
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

        await triggerEditCommitInput();

        expect(findCommitEditElements()).toHaveLength(2);
      });

      it('should have two edit components when squash is enabled', async () => {
        createComponent(
          {
            mr: {
              squashIsSelected: true,
              enableSquashBeforeMerge: true,
            },
          },
          true,
        );

        await triggerEditCommitInput();

        expect(findCommitEditElements()).toHaveLength(2);
      });

      it('should have correct edit squash commit label', async () => {
        createComponent({
          mr: {
            commitsCount: 2,
            squashIsSelected: true,
            enableSquashBeforeMerge: true,
          },
        });

        await triggerEditCommitInput();

        expect(findFirstCommitEditLabel()).toBe('Squash commit message');
      });
    });

    describe('commits dropdown', () => {
      it('should not be rendered if squash is disabled', () => {
        createComponent();

        expect(findCommitDropdownElement().exists()).toBe(false);
      });

      it('should  be rendered if squash is enabled and there is more than 1 commit', async () => {
        createComponent({
          mr: { enableSquashBeforeMerge: true, squashIsSelected: true, commitsCount: 2 },
        });

        await triggerEditCommitInput();

        expect(findCommitDropdownElement().exists()).toBe(true);
      });
    });

    it('renders a tip including a link to docs on templates', async () => {
      createComponent();

      await triggerEditCommitInput();

      expect(findTipLink().exists()).toBe(true);
    });
  });

  describe('source and target branches diverged', () => {
    describe('when the MR is showing the Merge button', () => {
      it('does not display the diverged commits message if the source branch is not behind the target', () => {
        createComponent({ mr: { divergedCommitsCount: 0 } });

        const textBody = wrapper.text();

        expect(textBody).toEqual(
          expect.not.stringContaining('The source branch is 0 commits behind the target branch'),
        );
        expect(textBody).toEqual(
          expect.not.stringContaining('The source branch is 0 commit behind the target branch'),
        );
        expect(textBody).toEqual(
          expect.not.stringContaining('The source branch is behind the target branch'),
        );
      });

      describe('shows the diverged commits text when the source branch is behind the target', () => {
        it('when the MR can be merged', () => {
          createComponent({
            mr: { divergedCommitsCount: 9001 },
          });

          expect(wrapper.text()).toEqual(
            expect.stringContaining('The source branch is 9001 commits behind the target branch'),
          );
        });

        it('when the MR cannot be merged', () => {
          createComponent({
            mr: {
              divergedCommitsCount: 9001,
              userPermissions: { canMerge: false },
              canMerge: false,
            },
          });

          expect(wrapper.text()).toEqual(
            expect.stringContaining('The source branch is 9001 commits behind the target branch'),
          );
        });
      });
    });
  });

  describe('Merge button when pipeline has failed', () => {
    beforeEach(() => {
      createComponent({
        mr: { headPipeline: { status: 'FAILED' }, availableAutoMergeStrategies: [], hasCI: true },
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
      createComponent({ mr: { commitsCount: 2, enableSquashBeforeMerge: true } }, false);

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

        await triggerEditCommitInput();

        expect(finderFn()).toBe(initialValue);
      });

      it('should have updated value after graphql refetch', async () => {
        createDefaultGqlComponent();
        await waitForPromises();
        await triggerEditCommitInput();

        triggerApprovalUpdated();
        await waitForPromises();

        expect(finderFn()).toBe(updatedValue);
      });

      it('should not update if user has touched', async () => {
        createDefaultGqlComponent();
        await waitForPromises();
        await triggerEditCommitInput();

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
