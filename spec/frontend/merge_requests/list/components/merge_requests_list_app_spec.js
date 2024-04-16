import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getCountsQueryResponse, getQueryResponse } from 'jest/merge_requests/list/mock_data';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TOKEN_TYPE_AUTHOR } from '~/vue_shared/components/filtered_search_bar/constants';
import { mergeRequestListTabs } from '~/vue_shared/issuable/list/constants';
import { getSortOptions } from '~/issues/list/utils';
import MergeRequestsListApp from '~/merge_requests/list/components/merge_requests_list_app.vue';
import getMergeRequestsQuery from '~/merge_requests/list/queries/get_merge_requests.query.graphql';
import getMergeRequestsCountQuery from '~/merge_requests/list/queries/get_merge_requests_counts.query.graphql';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';

Vue.use(VueApollo);

let wrapper;

const findIssuableList = () => wrapper.findComponent(IssuableList);

function createComponent({ provide = {} } = {}) {
  const apolloProvider = createMockApollo([
    [getMergeRequestsCountQuery, jest.fn().mockResolvedValue(getCountsQueryResponse)],
    [getMergeRequestsQuery, jest.fn().mockResolvedValue(getQueryResponse)],
  ]);
  wrapper = shallowMount(MergeRequestsListApp, {
    provide: {
      fullPath: 'gitlab-org/gitlab',
      hasAnyMergeRequests: true,
      initialSort: '',
      isPublicVisibilityRestricted: false,
      isSignedIn: true,
      ...provide,
    },
    apolloProvider,
  });
}

describe('Merge requests list app', () => {
  it('does not render issuable list if hasAnyMergeRequests is false', async () => {
    createComponent({ provide: { hasAnyMergeRequests: false } });

    await waitForPromises();

    expect(findIssuableList().exists()).toBe(false);
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
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers: [] },
        ]);
      });
    });

    describe('when all tokens are available', () => {
      beforeEach(async () => {
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
      });

      it('renders all tokens', () => {
        const preloadedUsers = [
          { ...mockCurrentUser, id: convertToGraphQLId(TYPENAME_USER, mockCurrentUser.id) },
        ];

        expect(findIssuableList().props('searchTokens')).toMatchObject([
          { type: TOKEN_TYPE_AUTHOR, preloadedUsers },
        ]);
      });
    });
  });
});
