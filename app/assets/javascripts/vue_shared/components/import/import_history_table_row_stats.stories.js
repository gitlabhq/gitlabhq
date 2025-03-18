import { basic } from 'jest/vue_shared/components/import/history_mock_data';

import ImportHistoryTableRowStats from './import_history_table_row_stats.vue';

export default {
  component: ImportHistoryTableRowStats,
  title: 'vue_shared/import/import_history_table_row_stats',
};

const defaultProps = {
  item: basic.items[0],
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableRowStats },
  props: Object.keys(argTypes),
  template: `<import-history-table-row-stats v-bind="$props"/>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
