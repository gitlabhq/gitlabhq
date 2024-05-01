import MergeRequest from './merge_request.vue';

const Template = (_, { argTypes }) => {
  return {
    components: { MergeRequest },
    props: Object.keys(argTypes),
    template: '<merge-request v-bind="$props" />',
  };
};

export default {
  component: MergeRequest,
  title: 'merge_requests_dashboard/merge_request',
};

export const Default = Template.bind({});
Default.args = {
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
        {
          id: 'gid://gitlab/GroupLabel/3103452',
          color: '#E44D2A',
          title: 'devops::create',
          description: 'Label description',
        },
        {
          id: 'gid://gitlab/GroupLabel/2975007',
          color: '#F0AD4E',
          title: 'feature::enhancement',
          description: 'Label description',
        },
        {
          id: 'gid://gitlab/GroupLabel/3412464',
          color: '#3cb371',
          title: 'frontend',
          description: 'Label description',
        },
        {
          id: 'gid://gitlab/GroupLabel/16934793',
          color: '#A8D695',
          title: 'group::code review',
          description: 'Label description',
        },
        {
          id: 'gid://gitlab/GroupLabel/14918378',
          color: '#F0AD4E',
          title: 'section::dev',
          description: 'Label description',
        },
        {
          id: 'gid://gitlab/GroupLabel/10230929',
          color: '#009966',
          title: 'type::feature',
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
    headPipeline: {
      id: 'gid://gitlab/Ci::Pipeline/1',
      detailedStatus: {
        id: 'success-1',
        icon: 'status_success',
        text: 'Passed',
        detailsPath: '/',
      },
    },
    userDiscussionsCount: 5,
    createdAt: '2024-04-22T10:13:09Z',
    updatedAt: '2024-04-19T14:34:42Z',
  },
};
