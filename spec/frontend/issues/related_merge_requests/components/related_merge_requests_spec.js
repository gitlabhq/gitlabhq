import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RelatedMergeRequests from '~/issues/related_merge_requests/components/related_merge_requests.vue';
import relatedMergeRequestsQuery from '~/issues/related_merge_requests/queries/related_merge_requests.query.graphql';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

Vue.use(VueApollo);

const mockData = {
  data: {
    project: {
      id: 1,
      issue: {
        id: 1,
        relatedMergeRequests: {
          count: 2,
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            startCursor: 'eyJpZCI6IjEwNjEwIn0',
            endCursor: 'eyJpZCI6IjM0In0',
            __typename: 'PageInfo',
          },
          nodes: [
            {
              id: 'gid://gitlab/MergeRequest/42',
              reference: '!18',
              state: 'merged',
              title: ':star: hello world',
              createdAt: '2023-03-03T12:25:40Z',
              mergedAt: '2023-04-27T12:01:04Z',
              webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/merge_requests/18',
              milestone: {
                expired: false,
                id: 'gid://gitlab/Milestone/5',
                state: 'active',
                title: 'v4.0',
                __typename: 'Milestone',
              },
              project: {
                id: 1,
                fullPath: 'gitlab-ce',
              },
              assignees: {
                nodes: [],
                __typename: 'MergeRequestAssigneeConnection',
              },
              headPipeline: null,
              __typename: 'MergeRequest',
            },
            {
              id: 'gid://gitlab/MergeRequest/34',
              reference: '!10',
              state: 'opened',
              title: 'Draft: :parrot: Title with custom emoji',
              createdAt: '2022-09-23T14:33:32Z',
              mergedAt: null,
              webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-test/-/merge_requests/10',
              milestone: {
                expired: false,
                id: 'gid://gitlab/Milestone/5',
                state: 'active',
                title: 'v4.0',
                __typename: 'Milestone',
              },
              project: {
                id: 1,
                fullPath: 'gitlab-org',
              },
              assignees: {
                nodes: [
                  {
                    id: 'gid://gitlab/User/1',
                    avatarUrl:
                      'https://www.gravatar.com/avatar/258d8dc916db8cea2cafb6c3cd0cb0246efe061421dbd83ec3a350428cabda4f?s=80\u0026d=identicon',
                    name: 'Administrator',
                    username: 'root',
                    webUrl: 'http://gdk.test:3000/root',
                    webPath: '/root',
                    __typename: 'MergeRequestAssignee',
                  },
                ],
                __typename: 'MergeRequestAssigneeConnection',
              },
              headPipeline: {
                id: 1,
                detailedStatus: {
                  id: 'success-66-66',
                  icon: 'status_success',
                  text: 'Passed',
                  detailsPath: '/root/test-ci/-/pipelines/66',
                  __typename: 'DetailedStatus',
                },
                __typename: 'Pipeline',
              },
              __typename: 'MergeRequest',
            },
          ],
          __typename: 'MergeRequestConnection',
        },
        __typename: 'Issue',
      },
      __typename: 'Project',
    },
  },
};

describe('RelatedMergeRequests', () => {
  let wrapper;

  beforeEach(async () => {
    const apolloProvider = createMockApollo([
      [relatedMergeRequestsQuery, jest.fn().mockResolvedValue(mockData)],
    ]);
    wrapper = shallowMountExtended(RelatedMergeRequests, {
      apolloProvider,
      propsData: {
        projectPath: 'gitlab-ce',
        iid: '1',
      },
      stubs: {
        CrudComponent,
      },
    });

    await waitForPromises();
  });

  describe('template', () => {
    it('should render related merge request items', () => {
      expect(wrapper.findByTestId('crud-count').text()).toBe('2');
      expect(wrapper.findAllComponents(RelatedIssuableItem)).toHaveLength(2);

      const props = wrapper.findAllComponents(RelatedIssuableItem).at(1).props();
      const data = mockData.data.project.issue.relatedMergeRequests.nodes[1];

      expect(props.idKey).toEqual(34);
      expect(props.pathIdSeparator).toEqual('!');
      expect(props.assignees).toEqual(data.assignees.nodes);
      expect(props.isMergeRequest).toBe(true);
      expect(props.confidential).toEqual(false);
      expect(props.title).toEqual(data.title);
      expect(props.state).toEqual(data.state);
      expect(props.createdAt).toEqual(data.createdAt);
      expect(props.displayReference).toEqual('gitlab-org!10');
    });
  });
});
