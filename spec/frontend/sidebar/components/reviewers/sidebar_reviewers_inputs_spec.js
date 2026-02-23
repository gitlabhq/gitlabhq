import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarReviewersInputs from '~/sidebar/components/reviewers/sidebar_reviewers_inputs.vue';
import getMergeRequestReviewersQuery from '~/sidebar/queries/get_merge_request_reviewers.query.graphql';

Vue.use(VueApollo);

let wrapper;

const mockReviewersResponse = (nodes = []) => ({
  data: {
    namespace: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      issuable: {
        __typename: 'MergeRequest',
        id: 'gid://gitlab/MergeRequest/1',
        reviewers: {
          __typename: 'MergeRequestReviewerConnection',
          nodes,
        },
        userPermissions: {
          __typename: 'MergeRequestPermissions',
          adminMergeRequest: false,
        },
      },
    },
  },
});

function factory(queryResponse) {
  const queryHandler = jest.fn().mockResolvedValue(queryResponse);
  const apolloProvider = createMockApollo([[getMergeRequestReviewersQuery, queryHandler]]);

  wrapper = shallowMount(SidebarReviewersInputs, {
    apolloProvider,
    provide: {
      issuableIid: '1',
      projectPath: 'projectPath',
    },
  });
}

describe('Sidebar reviewers inputs component', () => {
  it('renders hidden input', async () => {
    factory(
      mockReviewersResponse([
        {
          __typename: 'MergeRequestReviewer',
          id: 'gid://gitlab/User/1',
          avatarUrl: '',
          name: 'root',
          username: 'root',
          webUrl: '',
          webPath: '',
          status: null,
          type: 'human',
          mergeRequestInteraction: {
            __typename: 'UserMergeRequestInteraction',
            canMerge: true,
            canUpdate: true,
            approved: false,
            reviewState: null,
            applicableApprovalRules: [],
          },
        },
        {
          __typename: 'MergeRequestReviewer',
          id: 'gid://gitlab/User/2',
          avatarUrl: '',
          name: 'root2',
          username: 'root2',
          webUrl: '',
          webPath: '',
          status: null,
          type: 'human',
          mergeRequestInteraction: {
            __typename: 'UserMergeRequestInteraction',
            canMerge: true,
            canUpdate: true,
            approved: false,
            reviewState: null,
            applicableApprovalRules: [],
          },
        },
      ]),
    );

    await waitForPromises();

    expect(wrapper.findAll('input[type="hidden"]')).toHaveLength(2);
  });
});
