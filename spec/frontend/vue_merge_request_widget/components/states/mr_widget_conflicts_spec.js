import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import { removeBreakLine } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ConflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts.vue';

describe('MRWidgetConflicts', () => {
  let wrapper;
  let mergeRequestWidgetGraphql = null;
  const path = '/conflicts';

  const findResolveButton = () => wrapper.findByTestId('resolve-conflicts-button');
  const findMergeLocalButton = () => wrapper.findByTestId('merge-locally-button');

  const mergeConflictsText = 'Merge blocked: merge conflicts must be resolved.';
  const fastForwardMergeText =
    'Merge blocked: fast-forward merge is not possible. To merge this request, first rebase locally.';
  const userCannotMergeText =
    'Users who can write to the source or target branches can resolve the conflicts.';
  const resolveConflictsBtnText = 'Resolve conflicts';
  const mergeLocallyBtnText = 'Resolve locally';

  async function createComponent(propsData = {}) {
    wrapper = extendedWrapper(
      shallowMount(ConflictsComponent, {
        propsData,
        provide: {
          glFeatures: {
            mergeRequestWidgetGraphql,
          },
        },
        mocks: {
          $apollo: {
            queries: {
              userPermissions: { loading: false },
              stateData: { loading: false },
            },
          },
        },
      }),
    );

    if (mergeRequestWidgetGraphql) {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        userPermissions: {
          canMerge: propsData.mr.canMerge,
          pushToSourceBranch: propsData.mr.canPushToSourceBranch,
        },
        stateData: {
          shouldBeRebased: propsData.mr.shouldBeRebased,
          sourceBranchProtected: propsData.mr.sourceBranchProtected,
        },
      });
    }

    await nextTick();
  }

  afterEach(() => {
    mergeRequestWidgetGraphql = null;
    wrapper.destroy();
  });

  [false, true].forEach((featureEnabled) => {
    describe(`with GraphQL feature flag ${featureEnabled ? 'enabled' : 'disabled'}`, () => {
      beforeEach(() => {
        mergeRequestWidgetGraphql = featureEnabled;
      });

      // There are two permissions we need to consider:
      //
      // 1. Is the user allowed to merge to the target branch?
      // 2. Is the user allowed to push to the source branch?
      //
      // This yields 4 possible permutations that we need to test, and
      // we test them below. A user who can push to the source
      // branch should be allowed to resolve conflicts. This is
      // consistent with what the backend does.
      describe('when allowed to merge but not allowed to push to source branch', () => {
        beforeEach(async () => {
          await createComponent({
            mr: {
              canMerge: true,
              canPushToSourceBranch: false,
              conflictResolutionPath: path,
              conflictsDocsPath: '',
            },
          });
        });

        it('should tell you about conflicts without bothering other people', () => {
          expect(wrapper.text()).toContain(mergeConflictsText);
          expect(wrapper.text()).not.toContain(userCannotMergeText);
        });

        it('should not allow you to resolve the conflicts', () => {
          expect(wrapper.text()).not.toContain(resolveConflictsBtnText);
        });

        it('should have merge buttons', () => {
          expect(findMergeLocalButton().text()).toContain(mergeLocallyBtnText);
        });
      });

      describe('when not allowed to merge but allowed to push to source branch', () => {
        beforeEach(async () => {
          await createComponent({
            mr: {
              canMerge: false,
              canPushToSourceBranch: true,
              conflictResolutionPath: path,
              conflictsDocsPath: '',
            },
          });
        });

        it('should tell you about conflicts', () => {
          expect(wrapper.text()).toContain(mergeConflictsText);
          expect(wrapper.text()).toContain(userCannotMergeText);
        });

        it('should allow you to resolve the conflicts', () => {
          expect(findResolveButton().text()).toContain(resolveConflictsBtnText);
          expect(findResolveButton().attributes('href')).toEqual(path);
        });

        it('should not have merge buttons', () => {
          expect(wrapper.text()).not.toContain(mergeLocallyBtnText);
        });
      });

      describe('when allowed to merge and push to source branch', () => {
        beforeEach(async () => {
          await createComponent({
            mr: {
              canMerge: true,
              canPushToSourceBranch: true,
              conflictResolutionPath: path,
              conflictsDocsPath: '',
            },
          });
        });

        it('should tell you about conflicts without bothering other people', () => {
          expect(wrapper.text()).toContain(mergeConflictsText);
          expect(wrapper.text()).not.toContain(userCannotMergeText);
        });

        it('should allow you to resolve the conflicts', () => {
          expect(findResolveButton().text()).toContain(resolveConflictsBtnText);
          expect(findResolveButton().attributes('href')).toEqual(path);
        });

        it('should have merge buttons', () => {
          expect(findMergeLocalButton().text()).toContain(mergeLocallyBtnText);
        });
      });

      describe('when user does not have permission to push to source branch', () => {
        it('should show proper message', async () => {
          await createComponent({
            mr: {
              canMerge: false,
              canPushToSourceBranch: false,
              conflictsDocsPath: '',
            },
          });

          expect(wrapper.text().trim().replace(/\s\s+/g, ' ')).toContain(userCannotMergeText);
        });

        it('should not have action buttons', async () => {
          await createComponent({
            mr: {
              canMerge: false,
              canPushToSourceBranch: false,
              conflictsDocsPath: '',
            },
          });

          expect(findResolveButton().exists()).toBe(false);
          expect(findMergeLocalButton().exists()).toBe(false);
        });

        it('should not have resolve button when no conflict resolution path', async () => {
          await createComponent({
            mr: {
              canMerge: true,
              conflictResolutionPath: null,
              conflictsDocsPath: '',
            },
          });

          expect(findResolveButton().exists()).toBe(false);
        });
      });

      describe('when fast-forward or semi-linear merge enabled', () => {
        it('should tell you to rebase locally', async () => {
          await createComponent({
            mr: {
              shouldBeRebased: true,
              conflictsDocsPath: '',
            },
          });

          expect(removeBreakLine(wrapper.text()).trim()).toContain(fastForwardMergeText);
        });
      });

      describe('when source branch protected', () => {
        beforeEach(async () => {
          await createComponent({
            mr: {
              canMerge: true,
              canPushToSourceBranch: true,
              conflictResolutionPath: TEST_HOST,
              sourceBranchProtected: true,
              conflictsDocsPath: '',
            },
          });
        });

        it('should allow you to resolve the conflicts', () => {
          expect(findResolveButton().exists()).toBe(true);
        });
      });

      describe('when source branch not protected', () => {
        beforeEach(async () => {
          await createComponent({
            mr: {
              canMerge: true,
              canPushToSourceBranch: true,
              conflictResolutionPath: TEST_HOST,
              sourceBranchProtected: false,
              conflictsDocsPath: '',
            },
          });
        });

        it('should allow you to resolve the conflicts', () => {
          expect(findResolveButton().text()).toContain(resolveConflictsBtnText);
          expect(findResolveButton().attributes('href')).toEqual(TEST_HOST);
        });
      });
    });
  });
});
