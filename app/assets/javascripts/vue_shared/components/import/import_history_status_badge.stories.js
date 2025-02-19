import { IMPORT_HISTORY_TABLE_STATUS } from './constants';
import ImportHistoryStatusBadge from './import_history_status_badge.vue';

export default {
  component: ImportHistoryStatusBadge,
  title: 'vue_shared/import/import_history_status_badge',
  argTypes: {
    status: { control: { type: 'select', options: IMPORT_HISTORY_TABLE_STATUS } },
  },
};

const defaultProps = {
  status: 'started',
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryStatusBadge },
  props: Object.keys(argTypes),

  template: `<import-history-status-badge v-bind="$props" />`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
