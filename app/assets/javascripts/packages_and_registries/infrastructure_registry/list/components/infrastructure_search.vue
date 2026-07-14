<script>
import { mapState, mapActions } from 'pinia';
import { LIST_KEY_PACKAGE_TYPE } from '~/packages_and_registries/infrastructure_registry/list/constants';
import { useInfrastructureList } from '~/packages_and_registries/infrastructure_registry/list/stores';
import { sortableFields } from '~/packages_and_registries/infrastructure_registry/list/utils';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  name: 'InfrastructureSearch',
  components: { RegistrySearch, UrlSync },
  inject: {
    isGroupPage: {
      default: false,
    },
  },
  emits: ['update'],
  computed: {
    ...mapState(useInfrastructureList, ['sorting', 'filter']),
    sortableFields() {
      return sortableFields(this.isGroupPage).filter((h) => h.orderBy !== LIST_KEY_PACKAGE_TYPE);
    },
  },
  methods: {
    ...mapActions(useInfrastructureList, ['setSorting', 'setFilter']),
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
        :filters="filter"
        :sorting="sorting"
        :tokens="[] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
        :sortable-fields="sortableFields"
        @sorting:changed="updateSorting"
        @filter:changed="setFilter"
        @filter:submit="$emit('update')"
        @query:changed="updateQuery"
      />
    </template>
  </url-sync>
</template>
