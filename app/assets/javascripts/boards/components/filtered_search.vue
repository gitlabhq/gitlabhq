<script>
import { mapActions } from 'vuex';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

export default {
  i18n: {
    search: __('Search'),
  },
  components: { FilteredSearch },
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    initialSearch() {
      return [{ type: 'filtered-search-term', value: { data: this.search } }];
    },
  },
  methods: {
    ...mapActions(['performSearch']),
    handleSearch(filters) {
      let itemValue = '';
      const [item] = filters;

      if (filters.length === 0) {
        itemValue = '';
      } else {
        itemValue = item?.value?.data;
      }

      historyPushState(setUrlParams({ search: itemValue }, window.location.href));

      this.performSearch();
    },
  },
};
</script>

<template>
  <filtered-search
    class="gl-w-full"
    namespace=""
    :tokens="[]"
    :search-input-placeholder="$options.i18n.search"
    :initial-filter-value="initialSearch"
    @onFilter="handleSearch"
  />
</template>
