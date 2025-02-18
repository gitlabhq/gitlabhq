import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import MergeRequest from '~/merge_request_dashboard/components/merge_request.vue';
import StatusBadge from '~/merge_request_dashboard/components/status_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

Vue.use(VueApollo);

describe('Merge request dashboard merge request component', () => {
  let wrapper;

  const findBrokenBadge = () => wrapper.findByTestId('mr-broken-badge');

  function createComponent(mergeRequest = {}) {
    const mockApollo = createMockApollo();

    wrapper = shallowMountExtended(MergeRequest, {
      apolloProvider: mockApollo,
      propsData: {
        listId: 'returned_to_you',
        mergeRequest: {
          state: 'opened',
          reference: '!123456',
          title: 'Merge request title',
          author: {
            name: 'John Smith',
            webUrl: 'https://gitlab.com/root',
          },
          milestone: {
            title: '17.0',
          },
          assignees: {
            nodes: [
              {
                id: 'gid://gitlab/User/1',
                avatarUrl: '',
                name: 'John Smith',
                username: 'jsmith',
                webUrl: 'https://gitlab.com/root',
                webPath: '/root',
              },
            ],
          },
          reviewers: {
            nodes: [
              {
                id: 'gid://gitlab/User/1',
                avatarUrl: '',
                name: 'John Smith',
                username: 'jsmith',
                webUrl: 'https://gitlab.com/root',
                webPath: '/root',
              },
              {
                id: 'gid://gitlab/User/2',
                avatarUrl: '',
                name: 'John Smith',
                username: 'jsmith',
                webUrl: 'https://gitlab.com/root',
                webPath: '/root',
              },
            ],
          },
          userNotesCount: 5,
          createdAt: '2024-04-22T10:13:09Z',
          updatedAt: '2024-04-19T14:34:42Z',
          diffStatsSummary: {
            fileCount: 1,
            additions: 100,
            deletions: 50,
          },
          ...mergeRequest,
        },
      },
    });
  }

  it('renders template', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders CI icon for headPipeline', () => {
    createComponent({
      headPipeline: {
        id: 'gid://gitlab/Ci::Pipeline/1',
        detailedStatus: {
          id: 'success-1',
          icon: 'status_success',
          text: 'Passed',
          detailsPath: '/',
        },
      },
    });

    expect(wrapper.findComponent(CiIcon).exists()).toBe(true);
    expect(wrapper.findComponent(CiIcon).props('status')).toEqual({
      id: 'success-1',
      icon: 'status_success',
      text: 'Passed',
      detailsPath: '/',
    });
  });

  it('renders status badge component', () => {
    createComponent({});

    expect(wrapper.findComponent(StatusBadge).exists()).toBe(true);
  });

  it.each`
    state       | exists   | test
    ${'opened'} | ${true}  | ${'renders'}
    ${'closed'} | ${false} | ${'does not render'}
    ${'merged'} | ${false} | ${'does not render'}
  `('$test broken badge when state is $state', ({ state, exists }) => {
    createComponent({ state });

    expect(findBrokenBadge().exists()).toBe(exists);
  });
});
