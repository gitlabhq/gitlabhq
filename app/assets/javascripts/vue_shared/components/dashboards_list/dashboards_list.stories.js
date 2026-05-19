import DashboardsList from './dashboards_list.vue';

export default {
  component: DashboardsList,
  title: 'vue_shared/components/dashboards_list/dashboards_list',
};

const Template = (args, { argTypes }) => ({
  components: { DashboardsList },
  props: Object.keys(argTypes),
  template: `<dashboards-list :dashboards="dashboards" />`,
});

const defaultArgs = {
  dashboards: [
    {
      name: 'Built in dashboard',
      description: 'Built in dashboard',
      slug: 'built-in', // might need `url` instead once they are shareable
      system: true,
      isCustom: false,
      isStarred: true,
      shareLink: '/fake/link/to/share',
      dashboardUrl: '/fake/dashboard/built-in',
    },
    {
      name: 'First custom dashboard',
      description: 'Default dashboard description',
      slug: 'first-custom-dashboard',
      createdBy: {
        id: 133737,
        name: 'Fake User',
        username: 'fakeuser',
        avatarUrl: '/fake/user/avatar.jpg',
        webPath: '/fake/user/web/path',
      },
      isCustom: true,
      isStarred: false,
      isEditable: true,
      shareLink: '/fake/link/to/share',
      updatedAt: '2025-09-10',
      dashboardUrl: '/fake/dashboard/1',
    },
    {
      name: 'Cool dashboard',
      description:
        'Cool custom dashboard that has a description that is very long and will most definitely overflow within its box because its long',
      slug: 'cool-custom-dashboard',
      createdBy: {
        id: 133737,
        name: 'Fake User',
        username: 'fakeuser',
        avatarUrl: '/fake/user/avatar.jpg',
        webPath: '/fake/user/web/path',
      },
      isCustom: true,
      isStarred: false,
      isEditable: true,
      shareLink: '/fake/link/to/share',
      updatedAt: '2025-10-28',
      dashboardUrl: '/fake/dashboard/2',
    },
  ],
};

export const Default = Template.bind({});
Default.args = defaultArgs;
