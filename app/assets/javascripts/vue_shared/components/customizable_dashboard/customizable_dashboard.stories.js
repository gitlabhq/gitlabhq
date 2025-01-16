import { s__ } from '~/locale';
import CustomizableDashboard from './customizable_dashboard.vue';

export default {
  component: CustomizableDashboard,
  title: 'vue_shared/components/customizable_dashboard',
};

const Template = (args, { argTypes }) => ({
  components: { CustomizableDashboard },
  props: Object.keys(argTypes),
  template: '<customizable-dashboard v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  editable: false,
  initialDashboard: {
    title: 'Dashboard',
    description: 'Test description',
    panels: [
      {
        component: 'CubeLineChart',
        title: s__('ProductAnalytics|Audience'),
        gridAttributes: {
          width: 3,
          height: 3,
        },
      },
      {
        component: 'CubeLineChart',
        title: s__('ProductAnalytics|Audience'),
        gridAttributes: {
          width: 3,
          height: 3,
        },
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
  editable: true,
};
