import { MOCK_FIELDS, MOCK_ISSUES } from 'jest/glql/mock_data';
import TablePresenter from './table.vue';

export default {
  component: TablePresenter,
  title: 'glql/components/presenters/table',
  argTypes: {
    data: { control: false, description: 'Query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Fields the query selected, one column each.' },
    loading: {
      control: 'boolean',
      description: 'Boolean, or the number of skeleton rows to render.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { TablePresenter },
  props: Object.keys(argTypes),
  template: `<table-presenter :data="data" :fields="fields" :loading="loading" />`,
});

// Click a column header to sort by it.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_ISSUES,
  fields: MOCK_FIELDS,
  loading: false,
};

// Skeleton rows sit under the rows already loaded, which is how a "load more" reads.
export const LoadingMore = Template.bind({});
LoadingMore.args = {
  ...Default.args,
  loading: true,
};

// A number sets how many skeleton rows to render, so the placeholder matches the
// page size that is on its way.
export const LoadingFirstPage = Template.bind({});
LoadingFirstPage.args = {
  ...Default.args,
  data: { nodes: [] },
  loading: 3,
};

// Headers still render, so the columns a query selected stay visible.
export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};
