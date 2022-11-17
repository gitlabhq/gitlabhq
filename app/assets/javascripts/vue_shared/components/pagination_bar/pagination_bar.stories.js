import PaginationBar from './pagination_bar.vue';

export default {
  component: PaginationBar,
  title: 'vue_shared/pagination_bar/pagination_bar',
};

const Template = (args, { argTypes }) => ({
  components: { PaginationBar },
  props: Object.keys(argTypes),
  template: `<pagination-bar v-bind="$props" v-on="{ 'set-page-size': setPageSize, 'set-page': setPage }" />`,
});

export const Default = Template.bind({});

Default.args = {
  pageInfo: {
    perPage: 20,
    page: 2,
    total: 83,
    totalPages: 5,
  },
  pageSizes: [20, 50, 100],
};

Default.argTypes = {
  pageInfo: {
    description: 'Page info object',
    control: { type: 'object' },
  },
  pageSizes: {
    description: 'Array of possible page sizes',
    control: { type: 'array' },
  },

  // events
  setPageSize: { action: 'set-page-size' },
  setPage: { action: 'set-page' },
};
