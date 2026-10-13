import Pagination from './pagination.vue';

export default {
  component: Pagination,
  title: 'glql/components/common/pagination',
  argTypes: {
    count: { control: 'number', description: 'Number of items currently loaded.' },
    totalCount: { control: 'number', description: 'Total number of items available.' },
    pageSize: { control: 'number', description: 'Items requested per "load more" click.' },
    loading: { control: 'boolean' },

    // events
    loadMore: { action: 'load-more' },
  },
};

const Template = (args, { argTypes }) => ({
  components: { Pagination },
  props: Object.keys(argTypes),
  template: `<pagination
    :count="count"
    :total-count="totalCount"
    :page-size="pageSize"
    :loading="loading"
    v-on="{ 'load-more': loadMore }"
  />`,
});

export const Default = Template.bind({});
Default.args = {
  count: 20,
  totalCount: 100,
  pageSize: 20,
  loading: false,
};

export const Loading = Template.bind({});
Loading.args = {
  ...Default.args,
  loading: true,
};

// The button label counts down to the remainder rather than showing a full page.
export const SmallRemainder = Template.bind({});
SmallRemainder.args = {
  count: 95,
  totalCount: 100,
  pageSize: 20,
  loading: false,
};

// Renders nothing: the container is only shown while there is a next page.
export const NoNextPage = Template.bind({});
NoNextPage.args = {
  count: 100,
  totalCount: 100,
  pageSize: 20,
  loading: false,
};
