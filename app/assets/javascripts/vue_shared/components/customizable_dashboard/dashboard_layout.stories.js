import DashboardLayout from './dashboard_layout.vue';

export default {
  component: DashboardLayout,
  title: 'vue_shared/components/customizable_dashboard/dashboard_layout',
};

const dashboardConfig = {
  title: 'Dashboard title',
  description: 'This is my dashboard description',
  panels: [
    {
      id: '1',
      title: 'A dashboard panel',
      gridAttributes: {
        width: 6,
        height: 1,
        yPos: 0,
        xPos: 3,
      },
    },
  ],
};

const Template = (args, { argTypes }) => ({
  components: { DashboardLayout },
  props: Object.keys(argTypes),
  template: `
    <dashboard-layout v-bind="$props">
      <template #panel="{ panel }">
        <div class="gl-bg-blue-50 gl-h-full">
          {{ panel.title }}
        </div>
      </template>
      <template #empty-state>
        <p>This dashboard has no panels</p>
      </template>
    </dashboard-layout>
  `,
});

export const Default = Template.bind({});
Default.args = {
  config: { ...dashboardConfig },
};
