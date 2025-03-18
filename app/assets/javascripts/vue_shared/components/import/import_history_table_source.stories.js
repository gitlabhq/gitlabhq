import { basic } from 'jest/vue_shared/components/import/history_mock_data';

import ImportHistoryTableSource from './import_history_table_source.vue';

export default {
  component: ImportHistoryTableSource,
  title: 'vue_shared/import/import_history_table_source',
};

const defaultProps = {
  item: basic.items[0],
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableSource },
  props: Object.keys(argTypes),
  template: `<import-history-table-source v-bind="$props"/>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
