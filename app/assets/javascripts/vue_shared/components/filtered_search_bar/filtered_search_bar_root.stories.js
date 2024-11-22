import FilteredSearchBarRoot from './filtered_search_bar_root.vue';

export default {
  component: FilteredSearchBarRoot,
  title: 'vue_shared/components/filtered_search_bar/filtered_search_bar_root',
};

const Template = (args, { argTypes }) => ({
  components: { FilteredSearchBarRoot },
  props: Object.keys(argTypes),
  template: '<FilteredSearchBarRoot v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  namespace: 'explore',
  recentSearchesStorageKey: 'projects',
  tokens: [],
  sortOptions: [],
  initialFilterValue: [
    {
      type: 'filtered-search-term',
      value: {
        data: '',
      },
    },
  ],
  initialSortBy: '',
  showCheckbox: false,
  checkboxChecked: false,
  searchInputPlaceholder: 'Search or filter results…',
  suggestionsListClass: '',
  searchButtonAttributes: {},
  searchInputAttributes: {},
  showFriendlyText: false,
  syncFilterAndSort: true,
  termsAsTokens: true,
  searchTextOptionLabel: 'Search for this text',
  showSearchButton: true,
};
