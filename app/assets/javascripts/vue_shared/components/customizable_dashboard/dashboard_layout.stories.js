import DashboardLayout from './dashboard_layout.vue';
import ExtendedDashboardPanel from './extended_dashboard_panel.vue';

export default {
  component: DashboardLayout,
  title: 'vue_shared/components/customizable_dashboard/dashboard_layout',
};

const dashboardConfig = {
  title: 'Dashboard title',
  description: 'Dashboards made easy with a snap grid system',
  panels: [
    {
      id: '1',
      title: 'Dashboard panel',
      gridAttributes: {
        width: 6,
        height: 1,
        yPos: 0,
        xPos: 3,
      },
    },
    {
      id: '2',
      title: 'Another dashboard panel',
      gridAttributes: {
        width: 3,
        height: 2,
        yPos: 1,
        xPos: 1,
      },
    },
    {
      id: '3',
      title: 'I can be placed anywhere on the grid',
      gridAttributes: {
        width: 4,
        height: 1,
        yPos: 2,
        xPos: 7,
      },
    },
  ],
};

const Template = (args, { argTypes }) => ({
  components: { DashboardLayout, ExtendedDashboardPanel },
  props: Object.keys(argTypes),
  template: `
    <dashboard-layout v-bind="$props">
      <template #panel="{ panel }">
        <extended-dashboard-panel :title="panel.title" class="gl-h-full">
          <template #body>
            <p class="gl-text-tertiary">Your visualization here</p>
          </template>
        </extended-dashboard-panel>
      </template>
      <template #empty-state>
        <p>No dashboard panels here 🕵</p>
      </template>
    </dashboard-layout>
  `,
});

const SlotsTemplate = (args, { argTypes }) => ({
  components: { DashboardLayout },
  props: Object.keys(argTypes),
  template: `
    <dashboard-layout v-bind="$props">
      <template #title>
        <h2>
          Custom dashboard <code>#title</code> 🚀
        </h2>
      </template>
      <template #description>
        <div class="gl-text-subtle">
          This is the <code>#description</code> slot.
        </div>
      </template>
      <template #filters>
        <div class>
          Add your dashboard-level filters in the <code>#filters</code> slot.
        </div>
      </template>
      <template #actions>
        <a href="#" class="gl-display-flex"><code>#actions</code></a>
      </template>
      <template #alert>
        <div class="gl-text-danger">
          Dashboard alerts go in the <code>#alert</code> slot.
        </div>
      </template>
      <template #panel="{ panel }">
        <div class="gl-bg-feedback-warning gl-h-full">
          <p>The <code>#panel</code> slot.</p>
        </div>
      </template>
      <template #empty-state>
        <p>This dashboard has no panels</p>
      </template>
      <template #footer>
        <div class="gl-text-subtle">
          This is a custom <code>#footer</code>!
        </div>
      </template>
    </dashboard-layout>
  `,
});

export const Default = Template.bind({});
Default.args = {
  config: { ...dashboardConfig },
};

export const EmptyState = Template.bind({});
EmptyState.args = {
  config: {
    ...dashboardConfig,
    panels: [],
  },
};

export const Slots = SlotsTemplate.bind({});
Slots.args = {
  config: { ...dashboardConfig },
};
