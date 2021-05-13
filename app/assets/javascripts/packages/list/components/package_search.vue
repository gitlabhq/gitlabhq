<script>
import { mapState, mapActions } from 'vuex';
import { s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { sortableFields } from '../utils';
import PackageTypeToken from './tokens/package_type_token.vue';

export default {
  tokens: [
    {
      type: 'type',
      icon: 'package',
      title: s__('PackageRegistry|Type'),
      unique: true,
      token: PackageTypeToken,
      operators: OPERATOR_IS_ONLY,
    },
  ],
  components: { RegistrySearch, UrlSync },
  computed: {
    ...mapState({
      isGroupPage: (state) => state.config.isGroupPage,
      sorting: (state) => state.sorting,
      filter: (state) => state.filter,
    }),
    sortableFields() {
      return sortableFields(this.isGroupPage);
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
        :tokens="$options.tokens"
        :sortable-fields="sortableFields"
        @sorting:changed="updateSorting"
        @filter:changed="setFilter"
        @filter:submit="$emit('update')"
        @query:changed="updateQuery"
      />
    </template>
  </url-sync>
</template>
