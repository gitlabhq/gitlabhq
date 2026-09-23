import { MOCK_FIELDS, MOCK_ISSUES } from 'jest/glql/mock_data';
import List from './list.vue';

export default {
  component: List,
  title: 'glql/components/presenters/list',
  argTypes: {
    data: { control: false, description: 'Query result, as `{ nodes: [] }`.' },
    fields: { control: false, description: 'Fields the query selected.' },
    listType: { control: { type: 'select' }, options: ['ul', 'ol'] },
    loading: {
      control: 'boolean',
      description: 'Boolean, or the number of skeleton rows to render.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { List },
  props: Object.keys(argTypes),
  template: `<list
    :data="data"
    :fields="fields"
    :list-type="listType"
    :loading="loading"
  />`,
});

// The item's title field becomes the heading; the rest render beneath it.
export const Default = Template.bind({});
Default.args = {
  data: MOCK_ISSUES,
  fields: MOCK_FIELDS,
  listType: 'ul',
  loading: false,
};

export const Ordered = Template.bind({});
Ordered.args = {
  ...Default.args,
  listType: 'ol',
};

// Without the title field selected there is no heading, so every field reads as
// one compact line.
export const NoTitleField = Template.bind({});
NoTitleField.args = {
  ...Default.args,
  fields: MOCK_FIELDS.filter((field) => field.key !== 'title'),
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

export const NoData = Template.bind({});
NoData.args = {
  ...Default.args,
  data: { nodes: [] },
};
