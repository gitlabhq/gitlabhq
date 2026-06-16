import DataTable from './data_table.vue';
import DiffLineChanges from './diff_line_changes.vue';

export default {
  component: DiffLineChanges,
  title: 'analytics/analytics_dashboards/components/visualizations/data_table/diff_line_changes',
};

const Template = (args, { argTypes }) => ({
  components: { DiffLineChanges },
  props: Object.keys(argTypes),
  template: `<diff-line-changes :additions="additions" :deletions="deletions" />`,
});

const TableTemplate = (args, { argTypes }) => ({
  components: { DataTable },
  props: Object.keys(argTypes),
  template: `<data-table :data="data" :options="options" />`,
});

export const Default = Template.bind({});
Default.args = { additions: 10, deletions: 10 };

export const InTable = TableTemplate.bind({});
InTable.args = {
  data: {
    nodes: [
      { title: 'No changes' },
      {
        title: 'Small change',
        changes: {
          additions: 10,
          deletions: 10,
        },
      },
      {
        title: 'Medium change',
        changes: {
          additions: 100,
          deletions: 200,
        },
      },
      {
        title: 'Large change',
        changes: {
          additions: 10000,
          deletions: 500,
        },
      },
    ],
  },
  options: {
    fields: [
      { key: 'title' },
      { key: 'changes', label: 'Lines changed', component: 'DiffLineChanges' },
    ],
  },
};
