import SearchAndSortBar from './search_and_sort_bar.vue';

export default {
  component: SearchAndSortBar,
  title: 'usage_quotas/search_bar',
};

const Template = (_, { argTypes }) => ({
  components: { SearchAndSortBar },
  props: Object.keys(argTypes),
  template: `<search-and-sort-bar v-bind="$props" />`,
});
export const Default = Template.bind({});

Default.args = {
  namespace: '42',
  searchInputPlaceholder: 'search',
};
