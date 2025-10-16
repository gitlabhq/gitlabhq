import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  HTTP_STATUS_SERVICE_UNAVAILABLE,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import eventHub from '~/merge_request_dashboard/event_hub';
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
    mergeRequests = [createMockMergeRequest({ title: 'reviewer' })],
  ) {
    reviewerQueryMock =
      reviewerQueryMock ||
      jest.fn().mockResolvedValue({
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
              nodes: mergeRequests,
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

  afterEach(() => {
    reviewerQueryMock = null;
  });

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
        count: null,
        mergeRequests: expect.arrayContaining([
          expect.objectContaining({
            title,
          }),
        ]),
      }),
    );
  });

  it('renders `count` as `null` when count query hasnt completed', () => {
    createComponent();

    expect(slotSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        count: null,
      }),
    );
  });

  describe('when refetching', () => {
    it('refetches merge requests with eventHub emit event and query type matches', async () => {
      createComponent(
        { query: 'reviewRequestedMergeRequests', variables: { state: 'opened' } },
        [],
      );

      await waitForPromises();

      eventHub.$emit('refetch.mergeRequests', 'reviewRequestedMergeRequests');

      await waitForPromises();

      expect(reviewerQueryMock.mock.calls).toHaveLength(2);
      expect(reviewerQueryMock.mock.calls[1][0]).toEqual(expect.objectContaining({ perPage: 20 }));
    });

    it('does not refetch merge requests with eventHub emit event and query type does not matches', async () => {
      createComponent();

      await waitForPromises();

      eventHub.$emit('refetch.mergeRequests', 'assignedMergeRequests');

      await waitForPromises();

      expect(reviewerQueryMock.mock.calls).toHaveLength(1);
    });
  });

  describe('when 503 error gets thrown', () => {
    it('retries merge request query', async () => {
      const error503 = {
        statusCode: HTTP_STATUS_SERVICE_UNAVAILABLE,
        result: {
          errors: [{ message: 'Service temporarily unavailable' }],
        },
      };

      reviewerQueryMock = jest
        .fn()
        .mockRejectedValueOnce(error503)
        .mockResolvedValueOnce({
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

      createComponent();

      await waitForPromises();

      expect(reviewerQueryMock.mock.calls).toHaveLength(2);
    });
  });

  it('returns error prop when error gets thrown', async () => {
    const error = {
      statusCode: HTTP_STATUS_INTERNAL_SERVER_ERROR,
      result: {
        errors: [{ message: 'Service temporarily unavailable' }],
      },
    };

    reviewerQueryMock = jest.fn().mockRejectedValueOnce(error);

    createComponent();

    await waitForPromises();

    expect(slotSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        error: true,
        loading: false,
      }),
    );
  });
});
