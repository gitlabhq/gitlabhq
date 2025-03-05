import { basic } from 'jest/vue_shared/components/import/history_mock_data';
import ImportHistoryTable from './import_history_table.vue';

export default {
  component: ImportHistoryTable,
  title: 'vue_shared/import/import_history_table',
};

const defaultProps = basic;

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTable },
  data() {
    return {};
  },
  props: Object.keys(argTypes),
  template: `<import-history-table v-bind="$props" />`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
