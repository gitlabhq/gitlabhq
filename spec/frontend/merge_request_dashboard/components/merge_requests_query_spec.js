import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeRequestQuery from '~/merge_request_dashboard/components/merge_requests_query.vue';
import reviewerQuery from '~/merge_request_dashboard/queries/reviewer.query.graphql';
import assigneeQuery from '~/merge_request_dashboard/queries/assignee.query.graphql';
import { createMockMergeRequest } from '../mock_data';

Vue.use(VueApollo);

describe('Merge requests query component', () => {
  let slotSpy;
  let reviewerQueryMock;
  let assigneeQueryMock;

  function createComponent(
    props = { query: 'reviewRequestedMergeRequests', variables: { state: 'opened' } },
  ) {
    reviewerQueryMock = jest.fn().mockResolvedValue({
      data: {
        currentUser: {
          id: 1,
          reviewRequestedMergeRequests: {
            count: 0,
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
            },
            nodes: [createMockMergeRequest({ titleHtml: 'reviewer' })],
          },
        },
      },
    });
    assigneeQueryMock = jest.fn().mockResolvedValue({
      data: {
        currentUser: {
          id: 1,
          assignedMergeRequests: {
            count: 0,
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: null,
              endCursor: null,
              __typename: 'PageInfo',
            },
            nodes: [createMockMergeRequest({ titleHtml: 'assignee' })],
          },
        },
      },
    });
    const apolloProvider = createMockApollo([
      [reviewerQuery, reviewerQueryMock],
      [assigneeQuery, assigneeQueryMock],
    ]);

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

    expect(reviewerQueryMock).toHaveBeenCalledWith({ perPage: 3, state: 'opened' });
  });

  it('calls assigneeQueryMock for assignee query', async () => {
    createComponent({ query: 'assignedMergeRequests', variables: { state: 'opened' } });

    await waitForPromises();

    expect(assigneeQueryMock).toHaveBeenCalledWith({ perPage: 3, state: 'opened' });
  });

  it.each([
    ['reviewRequestedMergeRequests', 'reviewer'],
    ['assignedMergeRequests', 'assignee'],
  ])('sets merge request prop for %p', async (query, titleHtml) => {
    createComponent({ query, variables: { state: 'opened' } });

    await waitForPromises();

    expect(slotSpy).toHaveBeenCalledWith(
      expect.objectContaining({
        mergeRequests: expect.arrayContaining([
          expect.objectContaining({
            titleHtml,
          }),
        ]),
      }),
    );
  });
});
