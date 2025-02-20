import { basic } from 'jest/vue_shared/components/import_history_table/mock_data';

import ImportHistoryTableRowErrors from './import_history_table_row_errors.vue';

export default {
  component: ImportHistoryTableRowErrors,
  title: 'vue_shared/import/import_history_table_row_errors',
};

const defaultProps = {
  item: basic.items[3],
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableRowErrors },
  props: Object.keys(argTypes),
  template: `<import-history-table-row-errors v-bind="$props"/>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
