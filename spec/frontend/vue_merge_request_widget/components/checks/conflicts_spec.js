import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ConflictsComponent from '~/vue_merge_request_widget/components/checks/conflicts.vue';
import conflictsStateQuery from '~/vue_merge_request_widget/queries/states/conflicts.query.graphql';

Vue.use(VueApollo);

let wrapper;
let apolloProvider;

function factory({
  status = 'success',
  canMerge = true,
  pushToSourceBranch = true,
  shouldBeRebased = false,
  sourceBranchProtected = false,
  mr = {},
  project = {
    id: 1,
    mergeRequest: {
      id: 1,
      shouldBeRebased,
      sourceBranchProtected,
      userPermissions: { canMerge, pushToSourceBranch },
    },
  },
} = {}) {
  apolloProvider = createMockApollo([
    [
      conflictsStateQuery,
      jest.fn().mockResolvedValue({
        data: {
          project,
        },
      }),
    ],
  ]);

  wrapper = mountExtended(ConflictsComponent, {
    apolloProvider,
    propsData: {
      mr,
      check: { status, identifier: 'CONFLICT' },
    },
  });
}

describe('Merge request merge checks conflicts component', () => {
  afterEach(() => {
    apolloProvider = null;
  });

  it('renders failure reason text', () => {
    factory();

    expect(wrapper.text()).toEqual('Merge conflicts must be resolved.');
  });

  it('does not render action buttons when project is null', async () => {
    factory({ status: 'FAILED', project: null });

    await waitForPromises();

    expect(wrapper.findAllByTestId('extension-actions-button')).toHaveLength(0);
  });

  it.each`
    conflictResolutionPath  | pushToSourceBranch | sourceBranchProtected | rendersConflictButton | rendersConflictButtonText
    ${'https://gitlab.com'} | ${true}            | ${false}              | ${true}               | ${'renders'}
    ${undefined}            | ${true}            | ${false}              | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${false}           | ${false}              | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${true}            | ${true}               | ${false}              | ${'does not render'}
    ${'https://gitlab.com'} | ${false}           | ${false}              | ${false}              | ${'does not render'}
    ${undefined}            | ${false}           | ${false}              | ${false}              | ${'does not render'}
  `(
    '$rendersConflictButtonText the conflict button for $conflictResolutionPath $pushToSourceBranch $sourceBranchProtected $rendersConflictButton',
    async ({
      conflictResolutionPath,
      pushToSourceBranch,
      sourceBranchProtected,
      rendersConflictButton,
    }) => {
      factory({
        status: 'FAILED',
        mr: { conflictResolutionPath },
        pushToSourceBranch,
        sourceBranchProtected,
      });

      await waitForPromises();

      const { length } = wrapper.findAllByTestId('extension-actions-button');

      expect(length).toBe(rendersConflictButton ? 2 : 1);

      expect(
        wrapper
          .findAllByTestId('extension-actions-button')
          .at(length - 1)
          .text(),
      ).toBe(rendersConflictButton ? 'Resolve conflicts' : 'Resolve locally');
    },
  );
});
