import DashboardCard from './dashboard_card.vue';

export default {
  component: DashboardCard,
  title: 'vue_shared/components/dashboards_list/dashboard_card',
};

const Template = (args, { argTypes }) => ({
  components: { DashboardCard },
  props: Object.keys(argTypes),
  template: `
    <ul class="gl-m-0 gl-list-none gl-p-0" style="max-width: 320px">
      <dashboard-card :dashboard="dashboard" />
    </ul>
  `,
});

export const Custom = Template.bind({});
Custom.args = {
  dashboard: {
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/1',
    name: 'First custom dashboard',
    description: 'Default dashboard description',
    slug: 'first-custom-dashboard',
    system: false,
    createdBy: {
      id: 'gid://gitlab/User/133737',
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webPath: '/fake/user/web/path',
    },
    updatedAt: '2025-09-10T09:30:00Z',
    dashboardUrl: '/fake/dashboard/1',
  },
};

// Slug-less custom dashboards seed their generated thumbnail from the id.
export const CustomWithoutSlug = Template.bind({});
CustomWithoutSlug.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/2',
    name: 'Second custom dashboard',
    slug: null,
    dashboardUrl: '/fake/dashboard/2',
  },
};

export const System = Template.bind({});
System.args = {
  dashboard: {
    id: 'gitlab:dashboard:duo_and_sdlc_trends',
    name: 'Duo and SDLC trends',
    description: 'Dashboard created and maintained by GitLab',
    slug: 'duo_and_sdlc_trends',
    system: true,
    dashboardUrl: '/fake/dashboard/duo_and_sdlc_trends',
  },
};

export const SystemAiImpact = Template.bind({});
SystemAiImpact.args = {
  dashboard: {
    id: 'gitlab:dashboard:dap_impact',
    name: 'AI impact analytics',
    description: 'Dashboard created and maintained by GitLab',
    slug: 'dap_impact',
    system: true,
    dashboardUrl: '/fake/dashboard/dap_impact',
  },
};
