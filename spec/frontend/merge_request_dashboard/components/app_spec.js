import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from '~/merge_request_dashboard/components/app.vue';
import MergeRequestsQuery from '~/merge_request_dashboard/components/merge_requests_query.vue';
import CollapsibleSection from '~/merge_request_dashboard/components/collapsible_section.vue';
import MergeRequest from '~/merge_request_dashboard/components/merge_request.vue';
import eventHub from '~/merge_request_dashboard/event_hub';
import mergeRequestSubscription from '~/merge_request_dashboard/queries/user_merge_request_updated.subscription.graphql';
import assigneeQuery from '~/merge_request_dashboard/queries/assignee.query.graphql';
import assigneeCountQuery from '~/merge_request_dashboard/queries/assignee_count.query.graphql';
import { createMockMergeRequest } from '../mock_data';

Vue.use(VueApollo);

describe('Merge requests app component', () => {
  let wrapper;
  let assigneeQueryMock;
  let subscriptionHandler;

  const findMergeRequests = () => wrapper.findAllComponents(MergeRequest);
  const findLoadMoreButton = () => wrapper.findByTestId('load-more');
  const findCountExplanation = () => wrapper.findByTestId('merge-request-count-explanation');

  const $router = {
    push: jest.fn(),
  };

  function createComponent(lists = null) {
    subscriptionHandler = createMockSubscription();
    assigneeQueryMock = jest.fn().mockResolvedValue({
      data: {
        currentUser: {
          id: 1,
          mergeRequests: {
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'startCursor',
              endCursor: 'endCursor',
              __typename: 'PageInfo',
            },
            nodes: [createMockMergeRequest({ titleHtml: 'assignee' })],
          },
        },
      },
    });
    const apolloProvider = createMockApollo(
      [
        [assigneeQuery, assigneeQueryMock],
        [
          assigneeCountQuery,
          jest.fn().mockResolvedValue({
            data: {
              currentUser: {
                id: 1,
                mergeRequests: {
                  count: 1,
                },
              },
            },
          }),
        ],
      ],
      {},
      { typePolicies: { Query: { fields: { currentUser: { merge: false } } } } },
    );
    apolloProvider.defaultClient.setRequestHandler(
      mergeRequestSubscription,
      () => subscriptionHandler,
    );

    window.gon.current_user_id = '1';

    jest.spyOn(eventHub, '$emit');

    wrapper = shallowMountExtended(App, {
      apolloProvider,
      propsData: {
        tabs: [
          {
            title: 'Needs attention',
            key: '',
            lists: lists || [
              [
                {
                  id: 'assigned',
                  title: 'Assigned merge requests',
                  query: 'assignedMergeRequests',
                  variables: { state: 'opened' },
                },
              ],
            ],
          },
          {
            title: 'merged',
            key: 'merged',
            lists: [],
          },
        ],
      },
      provide: {
        mergeRequestsSearchDashboardPath: '/search',
      },
      stubs: {
        MergeRequestsQuery,
        CollapsibleSection,
        GlLink,
      },
      mocks: {
        $router,
        $route: { params: { filter: '' } },
      },
    });
  }

  it('renders list of merge requests', async () => {
    createComponent();

    await waitForPromises();

    expect(findMergeRequests()).toHaveLength(1);
  });

  it('renders load more button', async () => {
    createComponent();

    await waitForPromises();

    findLoadMoreButton().vm.$emit('click');

    await waitForPromises();

    expect(assigneeQueryMock).toHaveBeenCalledWith(
      expect.objectContaining({ afterCursor: 'endCursor' }),
    );
  });

  it('with 1 list does not render active count explanation', async () => {
    createComponent([
      [
        {
          id: 'assigned',
          title: 'Assigned merge requests',
          query: 'assignedMergeRequests',
          variables: { state: 'opened' },
        },
      ],
    ]);

    await waitForPromises();

    expect(findMergeRequests()).toHaveLength(1);
    expect(findCountExplanation().exists()).toBe(false);
  });

  it('renders active count explanation when more than 1 list', async () => {
    createComponent([
      [
        {
          id: 'assigned',
          title: 'Assigned merge requests',
          query: 'assignedMergeRequests',
          variables: { state: 'opened' },
        },
      ],
      [
        {
          id: 'reviewer',
          title: 'Assigned merge requests',
          query: 'assignedMergeRequests',
          variables: { state: 'opened' },
        },
      ],
    ]);

    await waitForPromises();

    expect(findMergeRequests()).toHaveLength(2);
    expect(findCountExplanation().exists()).toBe(true);
  });

  it('does not call $router.push if clicking the current tab', async () => {
    createComponent();

    await wrapper.findByTestId('merge-request-dashboard-tab').vm.$emit('click');

    expect($router.push).not.toHaveBeenCalled();
  });

  it('calls $router.push when clicking different tab to current tab', async () => {
    createComponent();

    await wrapper.findAllByTestId('merge-request-dashboard-tab').at(1).vm.$emit('click');

    expect($router.push).toHaveBeenCalledWith({ path: 'merged' });
  });

  describe('subscription updates', () => {
    it('emits refetch.mergeRequests with assignedMergeRequests when current user is an assignee', async () => {
      createComponent();

      await waitForPromises();

      subscriptionHandler.next({
        data: {
          userMergeRequestUpdated: {
            id: 1,
            assignees: {
              nodes: [
                {
                  id: 'gid://gitlab/User/1',
                },
              ],
            },
            author: { id: 'gid://gitlab/User/1' },
            reviewers: { nodes: [] },
          },
        },
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('refetch.mergeRequests', 'assignedMergeRequests');
      expect(eventHub.$emit).toHaveBeenCalledWith(
        'refetch.mergeRequests',
        'authorOrAssigneeMergeRequests',
      );
    });

    it('emits refetch.mergeRequests with assignedMergeRequests when current user is a reviewer', async () => {
      createComponent();

      await waitForPromises();

      subscriptionHandler.next({
        data: {
          userMergeRequestUpdated: {
            id: 1,
            reviewers: {
              nodes: [
                {
                  id: 'gid://gitlab/User/1',
                },
              ],
            },
            author: { id: 'gid://gitlab/User/1' },
            assignees: { nodes: [] },
          },
        },
      });

      expect(eventHub.$emit).toHaveBeenCalledWith(
        'refetch.mergeRequests',
        'reviewRequestedMergeRequests',
      );
    });
  });
});
