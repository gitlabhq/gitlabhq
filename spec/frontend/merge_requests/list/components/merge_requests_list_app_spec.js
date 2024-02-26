import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getCountsQueryResponse, getQueryResponse } from 'jest/merge_requests/list/mock_data';
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
});
