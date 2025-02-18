import { basic } from 'jest/vue_shared/components/import_history_table/mock_data';

import ImportHistoryTableRowDestination from './import_history_table_row_destination.vue';

export default {
  component: ImportHistoryTableRowDestination,
  title: 'vue_shared/import/import_history_table_row_destination',
};

const defaultProps = {
  item: basic.items[0],
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableRowDestination },
  props: Object.keys(argTypes),
  template: `<import-history-table-row-destination v-bind="$props"/>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
