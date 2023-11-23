import { mount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { TEST_HOST } from 'helpers/test_constants';
import { removeBreakLine } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import userPermissionsQuery from '~/vue_merge_request_widget/queries/permissions.query.graphql';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';
import ConflictsComponent from '~/vue_merge_request_widget/components/states/mr_widget_conflicts.vue';

Vue.use(VueApollo);

describe('MRWidgetConflicts', () => {
  let wrapper;
  const path = '/conflicts';

  const findResolveButton = () => wrapper.findByTestId('resolve-conflicts-button');
  const findMergeLocalButton = () => wrapper.findByTestId('merge-locally-button');

  const mergeConflictsText = 'merge conflicts must be resolved.';
  const fastForwardMergeText =
    'fast-forward merge is not possible. To merge this request, first rebase locally.';
  const userCannotMergeText =
    'Users who can write to the source or target branches can resolve the conflicts.';
  const resolveConflictsBtnText = 'Resolve conflicts';
  const mergeLocallyBtnText = 'Resolve locally';

  const defaultApolloProvider = (mockData = {}) => {
    const userData = {
      data: {
        project: {
          id: 234,
          mergeRequest: {
            id: 234,
            userPermissions: {
              canMerge: mockData.canMerge || false,
              pushToSourceBranch: mockData.canPushToSourceBranch || false,
            },
          },
        },
      },
    };

    const mrData = {
      data: {
        project: {
          id: 234,
          mergeRequest: {
            id: 234,
            shouldBeRebased: mockData.shouldBeRebased || false,
            sourceBranchProtected: mockData.sourceBranchProtected || false,
            userPermissions: {
              pushToSourceBranch: mockData.canPushToSourceBranch || false,
            },
          },
        },
      },
    };

    return createMockApollo([
      [userPermissionsQuery, jest.fn().mockResolvedValue(userData)],
      [conflictsStateQuery, jest.fn().mockResolvedValue(mrData)],
    ]);
  };

  async function createComponent({
    propsData,
    queryData,
    apolloProvider = defaultApolloProvider(queryData),
  } = {}) {
    wrapper = extendedWrapper(
      mount(ConflictsComponent, {
        apolloProvider,
        propsData,
      }),
    );

    await waitForPromises();
  }

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
        propsData: {
          mr: {
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canMerge: true,
          canPushToSourceBranch: false,
          conflictResolutionPath: path,
        },
      });
    });

    it('should tell you about conflicts without bothering other people', () => {
      const text = removeBreakLine(wrapper.text()).trim();
      expect(text).toContain(mergeConflictsText);
      expect(text).not.toContain(userCannotMergeText);
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
        propsData: {
          mr: {
            conflictResolutionPath: path,
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canMerge: false,
          canPushToSourceBranch: true,
        },
      });
    });

    it('should tell you about conflicts', () => {
      const text = removeBreakLine(wrapper.text()).trim();
      expect(text).toContain(userCannotMergeText);
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
        queryData: {
          canMerge: true,
          canPushToSourceBranch: true,
        },
        propsData: {
          mr: {
            conflictResolutionPath: path,
            conflictsDocsPath: '',
          },
        },
      });
    });

    it('should tell you about conflicts without bothering other people', () => {
      const text = removeBreakLine(wrapper.text()).trim();
      expect(text).toContain(mergeConflictsText);
      expect(text).not.toContain(userCannotMergeText);
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
        propsData: {
          mr: {
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canMerge: false,
          canPushToSourceBranch: false,
        },
      });

      expect(wrapper.text().trim().replace(/\s\s+/g, ' ')).toContain(userCannotMergeText);
    });

    it('should not have action buttons', async () => {
      await createComponent({
        queryData: {
          canMerge: false,
          canPushToSourceBranch: false,
        },
        propsData: {
          mr: {
            conflictsDocsPath: '',
          },
        },
      });

      expect(findResolveButton().exists()).toBe(false);
      expect(findMergeLocalButton().exists()).toBe(false);
    });

    it('should not have resolve button when no conflict resolution path', async () => {
      await createComponent({
        propsData: {
          mr: {
            conflictResolutionPath: null,
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canMerge: true,
        },
      });

      expect(findResolveButton().exists()).toBe(false);
    });
  });

  describe('when fast-forward or semi-linear merge enabled', () => {
    it('should tell you to rebase locally', async () => {
      await createComponent({
        propsData: {
          mr: {
            conflictsDocsPath: '',
          },
        },
        queryData: {
          shouldBeRebased: true,
        },
      });

      expect(removeBreakLine(wrapper.text()).trim()).toContain(fastForwardMergeText);
    });
  });

  describe('when source branch protected', () => {
    beforeEach(async () => {
      await createComponent({
        propsData: {
          mr: {
            conflictResolutionPath: TEST_HOST,
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canMerge: true,
          sourceBranchProtected: true,
          canPushToSourceBranch: true,
        },
      });
    });

    it('should not allow you to resolve the conflicts', () => {
      expect(findResolveButton().exists()).toBe(false);
    });
  });

  describe('when source branch not protected', () => {
    beforeEach(async () => {
      await createComponent({
        propsData: {
          mr: {
            conflictResolutionPath: TEST_HOST,
            conflictsDocsPath: '',
          },
        },
        queryData: {
          canPushToSourceBranch: true,
          canMerge: true,
          sourceBranchProtected: false,
        },
      });
    });

    it('should allow you to resolve the conflicts', () => {
      expect(findResolveButton().text()).toContain(resolveConflictsBtnText);
      expect(findResolveButton().attributes('href')).toEqual(TEST_HOST);
    });
  });

  describe('error states', () => {
    it('when project is null due to expired session it does not throw', async () => {
      const fn = async () => {
        await createComponent({
          propsData: { mr: {} },
          apolloProvider: createMockApollo([
            [conflictsStateQuery, jest.fn().mockResolvedValue({ data: { project: null } })],
            [userPermissionsQuery, jest.fn().mockResolvedValue({ data: { project: null } })],
          ]),
        });
        await waitForPromises();
      };

      await expect(fn()).resolves.not.toThrow();
    });
  });
});
