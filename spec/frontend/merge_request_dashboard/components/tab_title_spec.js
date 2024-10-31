import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TabTitle from '~/merge_request_dashboard/components/tab_title.vue';
import reviewerCountQuery from '~/merge_request_dashboard/queries/reviewer_count.query.graphql';
import assigneeCountQuery from '~/merge_request_dashboard/queries/assignee_count.query.graphql';

Vue.use(VueApollo);

describe('Merge requests tab title component', () => {
  let reviewerCountQueryMock;
  let assigneeCountQueryMock;
  let wrapper;

  function createComponent(props = { queries: [] }) {
    reviewerCountQueryMock = jest.fn().mockResolvedValue({
      data: { currentUser: { id: 1, mergeRequests: { count: 1 } } },
    });
    assigneeCountQueryMock = jest
      .fn()
      .mockResolvedValue({ data: { currentUser: { id: 1, mergeRequests: { count: 1 } } } });
    const apolloProvider = createMockApollo(
      [
        [reviewerCountQuery, reviewerCountQueryMock],
        [assigneeCountQuery, assigneeCountQueryMock],
      ],
      {},
      { typePolicies: { Query: { fields: { currentUser: { merge: false } } } } },
    );

    wrapper = shallowMountExtended(TabTitle, {
      apolloProvider,
      propsData: {
        title: 'All',
        tabKey: 'all',
        ...props,
      },
    });
  }

  const findTabCount = () => wrapper.findByTestId('tab-count');

  it.each`
    queries                                                      | count
    ${['reviewRequestedMergeRequests']}                          | ${'1'}
    ${['reviewRequestedMergeRequests', 'assignedMergeRequests']} | ${'2'}
  `('sets count as $count for queries $queries', async ({ count, queries }) => {
    createComponent({ queries: queries.map((query) => ({ query })) });

    await waitForPromises();

    expect(findTabCount().text()).toBe(count);
  });
});
