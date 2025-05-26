import { s__ } from '~/locale';
import CustomizableDashboard from './customizable_dashboard.vue';

export default {
  component: CustomizableDashboard,
  title: 'vue_shared/components/customizable_dashboard',
};

const Template = (args, { argTypes }) => ({
  components: { CustomizableDashboard },
  props: Object.keys(argTypes),
  template: `
    <customizable-dashboard v-bind="$props">
      <template #panel="{ panel }">
        <div class="gl-bg-blue-50 gl-h-full">
          {{ panel.title }}
        </div>
      </template>
    </customizable-dashboard>
  `,
});

export const Default = Template.bind({});
Default.args = {
  editingEnabled: false,
  initialDashboard: {
    title: 'Dashboard',
    description: 'Test description',
    panels: [
      {
        id: '1',
        component: 'CubeLineChart',
        title: s__('ProductAnalytics|Audience'),
        gridAttributes: {
          width: 3,
          height: 3,
        },
        visualization: 'daily_active_users',
      },
      {
        id: '2',
        component: 'CubeLineChart',
        title: s__('ProductAnalytics|Events'),
        gridAttributes: {
          width: 3,
          height: 3,
        },
        visualization: 'daily_active_users',
      },
    ],
    userDefined: true,
    status: null,
    errors: null,
  },
  availableVisualizations: {
    loading: true,
    hasError: false,
    visualizations: [],
  },
};

export const Editable = Template.bind({});
Editable.args = {
  ...Default.args,
  editingEnabled: true,
};
