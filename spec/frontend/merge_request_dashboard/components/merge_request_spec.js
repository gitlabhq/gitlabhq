import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequest from '~/merge_request_dashboard/components/merge_request.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

describe('Merge request dashboard merge request component', () => {
  let wrapper;

  function createComponent(mergeRequest = {}) {
    wrapper = shallowMountExtended(MergeRequest, {
      propsData: {
        mergeRequest: {
          reference: '!123456',
          titleHtml: 'Merge request title',
          author: {
            name: 'John Smith',
            webUrl: 'https://gitlab.com/root',
          },
          milestone: {
            title: '17.0',
          },
          labels: {
            nodes: [
              {
                id: 'gid://gitlab/GroupLabel/992791',
                color: '#428BCA',
                title: 'Deliverable',
                description: 'Label description',
              },
            ],
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
          userDiscussionsCount: 5,
          createdAt: '2024-04-22T10:13:09Z',
          updatedAt: '2024-04-19T14:34:42Z',
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
});
