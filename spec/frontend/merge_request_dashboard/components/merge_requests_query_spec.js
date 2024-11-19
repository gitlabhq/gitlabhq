import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeRequestQuery from '~/merge_request_dashboard/components/merge_requests_query.vue';
import reviewerQuery from '~/merge_request_dashboard/queries/reviewer.query.graphql';
import reviewerCountQuery from '~/merge_request_dashboard/queries/reviewer_count.query.graphql';
import assigneeQuery from '~/merge_request_dashboard/queries/assignee.query.graphql';
import assigneeCountQuery from '~/merge_request_dashboard/queries/assignee_count.query.graphql';
import { createMockMergeRequest } from '../mock_data';

Vue.use(VueApollo);

describe('Merge requests query component', () => {
  let slotSpy;
  let reviewerQueryMock;
  let assigneeQueryMock;
  let assigneeCountQueryMock;

  function createComponent(
    props = { query: 'reviewRequestedMergeRequests', variables: { state: 'opened' } },
  ) {
    reviewerQueryMock = jest.fn().mockResolvedValue({
      data: {
        currentUser: {
          id: 1,
          mergeRequests: {
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
            },
            nodes: [createMockMergeRequest({ title: 'reviewer' })],
          },
        },
      },
    });
    assigneeQueryMock = jest.fn().mockResolvedValue({
      data: {
        currentUser: {
          id: 1,
          mergeRequests: {
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            nodes: [createMockMergeRequest({ title: 'assignee' })],
          },
        },
      },
    });
    assigneeCountQueryMock = jest
      .fn()
      .mockResolvedValue({ data: { currentUser: { id: 1, mergeRequests: { count: 1 } } } });
    const apolloProvider = createMockApollo(
      [
        [reviewerQuery, reviewerQueryMock],
        [assigneeQuery, assigneeQueryMock],
        [
          reviewerCountQuery,
          jest
            .fn()
            .mockResolvedValue({ data: { currentUser: { id: 1, mergeRequests: { count: 1 } } } }),
        ],
        [assigneeCountQuery, assigneeCountQueryMock],
      ],
      {},
      { typePolicies: { Query: { fields: { currentUser: { merge: false } } } } },
    );

    slotSpy = jest.fn();

    shallowMountExtended(MergeRequestQuery, {
      apolloProvider,
      propsData: {
        ...props,
      },
      scopedSlots: {
        default: slotSpy,
      },
    });
  }

  it('calls reviewerQueryMock for reviewer query', async () => {
    createComponent();

    await waitForPromises();

    expect(reviewerQueryMock).toHaveBeenCalledWith({
      perPage: 20,
      state: 'opened',
      sort: 'UPDATED_DESC',
    });
  });

  it('calls assigneeQueryMock for assignee query', async () => {
    createComponent({ query: 'assignedMergeRequests', variables: { state: 'opened' } });

    await waitForPromises();

    expect(assigneeQueryMock).toHaveBeenCalledWith({
      perPage: 20,
      state: 'opened',
      sort: 'UPDATED_DESC',
    });
  });

  it('does not call count query if hideCount is true', async () => {
    createComponent({
      query: 'assignedMergeRequests',
      variables: { state: 'opened' },
      hideCount: true,
    });

    await waitForPromises();

    expect(assigneeCountQueryMock).not.toHaveBeenCalled();
  });

  it.each([
    ['reviewRequestedMergeRequests', 'reviewer'],
    ['assignedMergeRequests', 'assignee'],
  ])('sets merge request prop for %p', async (query, title) => {
    createComponent({ query, variables: { state: 'opened' } });

    await waitForPromises();

    expect(slotSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        mergeRequests: expect.arrayContaining([
          expect.objectContaining({
            title,
          }),
        ]),
      }),
    );
  });
});
