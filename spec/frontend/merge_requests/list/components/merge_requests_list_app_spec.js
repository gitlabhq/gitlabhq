import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { getCountsQueryResponse, getQueryResponse } from 'jest/merge_requests/list/mock_data';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_DRAFT,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_REVIEWER,
  OPERATOR_IS,
  OPERATOR_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { mergeRequestListTabs } from '~/vue_shared/issuable/list/constants';
import { getSortOptions } from '~/issues/list/utils';
import MergeRequestsListApp from '~/merge_requests/list/components/merge_requests_list_app.vue';
import getMergeRequestsQuery from '~/merge_requests/list/queries/get_merge_requests.query.graphql';
import getMergeRequestsCountQuery from '~/merge_requests/list/queries/get_merge_requests_counts.query.graphql';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

let wrapper;
let router;
let getQueryResponseMock;
let getCountsQueryResponseMock;

const findIssuableList = () => wrapper.findComponent(IssuableList);
const findNewMrButton = () => wrapper.findByTestId('new-merge-request-button');

function createComponent({ provide = {} } = {}) {
  getQueryResponseMock = jest.fn().mockResolvedValue(getQueryResponse);
  getCountsQueryResponseMock = jest.fn().mockResolvedValue(getCountsQueryResponse);
  const apolloProvider = createMockApollo([
    [getMergeRequestsCountQuery, getCountsQueryResponseMock],
    [getMergeRequestsQuery, getQueryResponseMock],
  ]);
  router = new VueRouter({ mode: 'history' });
  router.push = jest.fn();

  wrapper = shallowMountExtended(MergeRequestsListApp, {
    provide: {
      fullPath: 'gitlab-org/gitlab',
      hasAnyMergeRequests: true,
      hasScopedLabelsFeature: false,
      initialSort: '',
      isPublicVisibilityRestricted: false,
      isSignedIn: true,
      newMergeRequestPath: '',
      ...provide,
    },
    apolloProvider,
    router,
  });
}

describe('Merge requests list app', () => {
  it('does not render issuable list if hasAnyMergeRequests is false', async () => {
    createComponent({ provide: { hasAnyMergeRequests: false } });

    await waitForPromises();

    expect(findIssuableList().exists()).toBe(false);
  });

  it('shows "New merge request" button', () => {
    createComponent({ provide: { newMergeRequestPath: '/new-mr-path' } });

    expect(findNewMrButton().exists()).toBe(true);
  });

  it('renders issuable list', async () => {
    createComponent();

    await waitForPromises();

    expect(findIssuableList().props()).toMatchObject({
      namespace: 'gitlab-org/gitlab',
      recentSearchesStorageKey: 'merge_requests',
      sortOptions: getSortOptions({ hasManualSort: false }),
      initialSortBy: 'CREATED_DESC',
      issuables: getQueryResponse.data.project.mergeRequests.nodes,
      tabs: mergeRequestListTabs,
      currentTab: 'opened',
      tabCounts: {
        opened: 1,
        merged: 1,
        closed: 1,
        all: 1,
      },
      issuablesLoading: false,
      isManualOrdering: false,
      showBulkEditSidebar: false,
      showPaginationControls: true,
      useKeysetPagination: true,
      hasPreviousPage: false,
      hasNextPage: true,
    });
  });

  describe('tokens', () => {
    const mockCurrentUser = {
      id: 1,
      name: 'Administrator',
      username: 'root',
      avatar_url: 'avatar/url',
    };

    describe('when user is signed out', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('does not have preloaded users when gon.current_user_id does not exist', () => {
        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER, preloadedUsers: [] },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers: [] },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
          { type: TOKEN_TYPE_LABEL },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      const urlParams = {
        assignee_username: 'bob',
        reviewer_username: 'bill',
        draft: 'yes',
        'label_name[]': 'fluff',
        milestone_title: 'milestone',
        'target_branches[]': 'branch-a',
        'source_branches[]': 'branch-b',
      };

      beforeEach(async () => {
        setWindowLocation(`?${new URLSearchParams(urlParams).toString()}`);
        window.gon = {
          current_user_id: mockCurrentUser.id,
          current_user_fullname: mockCurrentUser.name,
          current_username: mockCurrentUser.username,
          current_user_avatar_url: mockCurrentUser.avatar_url,
        };

        createComponent();

        await waitForPromises();
      });

      afterEach(() => {
        window.gon = {};
        setWindowLocation('?');
      });

      it('renders all tokens', () => {
        const preloadedUsers = [
          { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER, preloadedUsers },
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
          { type: TOKEN_TYPE_LABEL },
        ]);
      });

      it('pre-displays tokens that are in the url search parameters', () => {
        expect(findIssuableList().props('initialFilterValue')).toMatchObject([
          { type: TOKEN_TYPE_ASSIGNEE },
          { type: TOKEN_TYPE_REVIEWER },
          { type: TOKEN_TYPE_DRAFT },
          { type: TOKEN_TYPE_LABEL },
          { type: TOKEN_TYPE_MILESTONE },
          { type: TOKEN_TYPE_TARGET_BRANCH },
          { type: TOKEN_TYPE_SOURCE_BRANCH },
        ]);
      });
    });
  });

  describe('events', () => {
    describe('when "filter" event is emitted by IssuableList', () => {
      it('updates IssuableList with url params', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_IS },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_IS },
          },
        ]);
        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({
            'assignee_username[]': ['root'],
            reviewer_username: 'root',
          }),
        });
      });

      it('fetches new data with "not" variable', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_NOT },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_NOT },
          },
        ]);

        await nextTick();

        expect(getQueryResponseMock).toHaveBeenCalledWith(
          expect.objectContaining({
            not: { assigneeUsernames: ['root'], reviewerUsername: 'root' },
          }),
        );

        expect(getCountsQueryResponseMock).toHaveBeenCalledWith(
          expect.objectContaining({
            not: { assigneeUsernames: ['root'], reviewerUsername: 'root' },
          }),
        );
      });

      it('pushes new route with "not" values', async () => {
        createComponent();

        findIssuableList().vm.$emit('filter', [
          {
            type: 'assignee',
            value: { data: ['root'], operator: OPERATOR_NOT },
          },
          {
            type: 'reviewer',
            value: { data: 'root', operator: OPERATOR_NOT },
          },
        ]);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({
          query: expect.objectContaining({
            'not[assignee_username][]': ['root'],
            'not[reviewer_username]': 'root',
          }),
        });
      });
    });
  });
});
