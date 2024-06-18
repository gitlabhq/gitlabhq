import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import UpdateReviewers from '~/merge_requests/components/reviewers/update_reviewers.vue';
import ReviewersContainer from '~/merge_requests/components/reviewers/reviewers_container.vue';
import UncollapsedReviewerList from '~/sidebar/components/reviewers/uncollapsed_reviewer_list.vue';
import userPermissionsQuery from '~/merge_requests/components/reviewers/queries/user_permissions.query.graphql';
import setReviewersMutation from '~/merge_requests/components/reviewers/queries/set_reviewers.mutation.graphql';

let wrapper;
let setReviewersMutationHandler;

Vue.use(VueApollo);

function createComponent(propsData = {}, adminMergeRequest = true) {
  setReviewersMutationHandler = jest.fn().mockResolvedValue({
    data: { mergeRequestSetReviewers: { errors: null } },
  });

  const apolloProvider = createMockApollo([
    [
      userPermissionsQuery,
      jest.fn().mockResolvedValue({
        data: {
          project: { id: 1, mergeRequest: { id: 1, userPermissions: { adminMergeRequest } } },
        },
      }),
    ],
    [setReviewersMutation, setReviewersMutationHandler],
  ]);

  wrapper = shallowMountExtended(ReviewersContainer, {
    apolloProvider,
    propsData: {
      reviewers: [],
      loadingReviewers: false,
      ...propsData,
    },
    provide: {
      projectPath: 'gitlab-org/gitlab',
      issuableIid: '1',
    },
    stubs: {
      GlEmptyState,
      UpdateReviewers,
    },
  });
}

const findEmptyState = () => wrapper.findComponent(GlEmptyState);
const findAssignButton = () => wrapper.findComponent(GlButton);
const findReviewersList = () => wrapper.findComponent(UncollapsedReviewerList);
const findUpdateReviewers = () => wrapper.findComponent(UpdateReviewers);

describe('Reviewers container component', () => {
  beforeEach(() => {
    window.gon = { current_username: 'root' };
  });

  afterEach(() => {
    window.gon = {};
  });

  describe('when no reviewers exist', () => {
    it('renders empty state', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(true);
    });

    describe('when user has permission to add reviewers', () => {
      it('renders empty state with add reviewers button', async () => {
        createComponent();

        await waitForPromises();

        expect(findAssignButton().exists()).toBe(true);
      });

      it('sets current user as update-reviewers component prop', async () => {
        createComponent();

        await waitForPromises();

        expect(findUpdateReviewers().props('selectedReviewers')).toEqual(
          expect.arrayContaining(['root']),
        );
      });

      it('adds current user as reviewer', async () => {
        createComponent();

        await waitForPromises();

        findAssignButton().vm.$emit('click');

        await waitForPromises();

        expect(setReviewersMutationHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            reviewerUsernames: ['root'],
          }),
        );
      });
    });

    describe('when user does not have permission to add reviewers', () => {
      it('renders empty state with add reviewers button', async () => {
        createComponent({}, false);

        await waitForPromises();

        expect(findAssignButton().exists()).toBe(false);
      });
    });
  });

  it('renders reviewers list component', async () => {
    createComponent({ reviewers: ['test-reviewer'] });

    await waitForPromises();

    expect(findReviewersList().exists()).toBe(true);
    expect(findReviewersList().props()).toEqual(
      expect.objectContaining({
        users: ['test-reviewer'],
        issuableType: 'merge_request',
      }),
    );
  });
});
