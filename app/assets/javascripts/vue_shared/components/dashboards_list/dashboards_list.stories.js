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

const createdBy = {
  id: 'gid://gitlab/User/133737',
  name: 'Fake User',
  username: 'fakeuser',
  avatarUrl: '/fake/user/avatar.jpg',
  webPath: '/fake/user/web/path',
};

const defaultArgs = {
  dashboards: [
    {
      id: 'gitlab:dashboard:dap_impact',
      name: 'AI impact analytics',
      description: 'Dashboard created and maintained by GitLab',
      slug: 'dap_impact',
      system: true,
      dashboardUrl: '/fake/dashboard/dap_impact',
    },
    {
      id: 'gitlab:dashboard:duo_and_sdlc_trends',
      name: 'Duo and SDLC trends',
      description: 'Dashboard created and maintained by GitLab',
      slug: 'duo_and_sdlc_trends',
      system: true,
      dashboardUrl: '/fake/dashboard/duo_and_sdlc_trends',
    },
    {
      id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/1',
      name: 'First custom dashboard',
      description: 'Default dashboard description',
      slug: null,
      system: false,
      createdBy,
      updatedAt: '2025-09-10T09:04:53Z',
      dashboardUrl: '/fake/dashboard/1',
    },
    {
      id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/2',
      name: 'Cool dashboard',
      description:
        'Cool custom dashboard that has a description that is very long and will most definitely overflow within its box because its long',
      slug: null,
      system: false,
      createdBy,
      updatedAt: '2025-10-28T14:22:10Z',
      dashboardUrl: '/fake/dashboard/2',
    },
    {
      id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/3',
      name: 'Sprint health',
      description: 'Issue and MR flow for the current sprint',
      slug: 'sprint-health',
      system: false,
      createdBy,
      updatedAt: '2025-11-04T11:45:31Z',
      dashboardUrl: '/fake/dashboard/3',
    },
  ],
};

export const Default = Template.bind({});
Default.args = defaultArgs;
