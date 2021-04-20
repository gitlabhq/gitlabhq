<script>
import { mapState, mapActions } from 'vuex';
import { LIST_KEY_PACKAGE_TYPE } from '~/packages/list/constants';
import { sortableFields } from '~/packages/list/utils';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  components: { RegistrySearch, UrlSync },
  computed: {
    ...mapState({
      isGroupPage: (state) => state.config.isGroupPage,
      sorting: (state) => state.sorting,
      filter: (state) => state.filter,
    }),
    sortableFields() {
      return sortableFields(this.isGroupPage).filter((h) => h.orderBy !== LIST_KEY_PACKAGE_TYPE);
    },
  },
  methods: {
    ...mapActions(['setSorting', 'setFilter']),
    updateSorting(newValue) {
      this.setSorting(newValue);
      this.$emit('update');
    },
  },
};
</script>

<template>
  <url-sync>
    <template #default="{ updateQuery }">
      <registry-search
        :filter="filter"
        :sorting="sorting"
        :tokens="[]"
        :sortable-fields="sortableFields"
        @sorting:changed="updateSorting"
        @filter:changed="setFilter"
        @filter:submit="$emit('update')"
        @query:changed="updateQuery"
      />
    </template>
  </url-sync>
</template>
