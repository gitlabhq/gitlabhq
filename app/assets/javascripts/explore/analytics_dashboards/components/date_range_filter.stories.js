import DateRangeFilter from './date_range_filter.vue';
import { DEFAULT_SELECTED_DATE_RANGE_OPTION } from './constants';

export default {
  component: DateRangeFilter,
  title: 'explore/analytics_dashboards/components/date_range_filter',
};

const Template = (args, { argTypes }) => ({
  components: { DateRangeFilter },
  props: Object.keys(argTypes),
  template: `
    <div style="height:200px;" class="gl-py-3">
      <date-range-filter v-bind="$props" />
    </div>
  `,
});

const defaultArgs = {
  defaultOption: DEFAULT_SELECTED_DATE_RANGE_OPTION,
};

export const Default = Template.bind({});
Default.args = defaultArgs;

export const WithDateRangeLimit = Template.bind({});
WithDateRangeLimit.args = {
  ...defaultArgs,
  dateRangeLimit: 30,
};
