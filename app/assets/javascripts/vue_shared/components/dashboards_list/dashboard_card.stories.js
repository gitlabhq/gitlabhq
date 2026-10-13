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
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      webPath: '/fake/user/web/path',
    },
    updatedAt: '2025-09-10T09:30:00Z',
    dashboardUrl: '/fake/dashboard/1',
  },
};

// A config with panels renders the panel-mimicking thumbnail instead of the
// purely seeded one.
export const CustomWithConfig = Template.bind({});
CustomWithConfig.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/5',
    name: 'Custom dashboard with panels',
    slug: 'custom-dashboard-with-panels',
    dashboardUrl: '/fake/dashboard/5',
    config: {
      panels: [
        {
          title: 'Total users',
          visualization: { type: 'SingleStat' },
          gridAttributes: { yPos: 0, xPos: 0, width: 3, height: 1 },
        },
        {
          title: 'Active users',
          visualization: { type: 'SingleStat' },
          gridAttributes: { yPos: 0, xPos: 3, width: 3, height: 1 },
        },
        {
          title: 'Users over time',
          visualization: { type: 'LineChart' },
          gridAttributes: { yPos: 1, xPos: 0, width: 12, height: 4 },
        },
        {
          title: 'Top events',
          visualization: { type: 'DataTable' },
          gridAttributes: { yPos: 5, xPos: 0, width: 6, height: 4 },
        },
      ],
    },
  },
};

export const NoDescription = Template.bind({});
NoDescription.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/6',
    name: 'Dashboard without a description',
    description: '',
    slug: 'dashboard-without-a-description',
    dashboardUrl: '/fake/dashboard/6',
  },
};

// Deleted creators come back as null; the meta row keeps only the timestamp.
export const NoCreator = Template.bind({});
NoCreator.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/7',
    name: 'Dashboard without a creator',
    slug: 'dashboard-without-a-creator',
    createdBy: null,
    dashboardUrl: '/fake/dashboard/7',
  },
};

// Names are user-supplied, so a pasted slug or identifier can arrive unbroken.
export const LongUnbrokenName = Template.bind({});
LongUnbrokenName.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/8',
    name: 'a_very_long_unbroken_dashboard_name_pasted_from_an_identifier_or_slug_2025',
    slug: 'long-unbroken-name',
    dashboardUrl: '/fake/dashboard/8',
  },
};

export const LongDescription = Template.bind({});
LongDescription.args = {
  dashboard: {
    ...Custom.args.dashboard,
    id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/9',
    name: 'Dashboard with a long description',
    description:
      'This dashboard tracks the adoption of AI features across every project in the group, ' +
      'including code suggestions acceptance rates, chat usage, and the downstream effects on ' +
      'cycle time, deployment frequency, and change failure rate over the trailing twelve months.',
    slug: 'dashboard-with-a-long-description',
    dashboardUrl: '/fake/dashboard/9',
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
