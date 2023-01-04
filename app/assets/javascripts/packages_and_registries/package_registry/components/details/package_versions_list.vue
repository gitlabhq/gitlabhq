<script>
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';

export default {
  components: {
    VersionRow,
    PackagesListLoader,
    RegistryList,
  },
  props: {
    versions: {
      type: Array,
      required: true,
      default: () => [],
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isListEmpty() {
      return this.versions.length === 0;
    },
  },
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <packages-list-loader />
    </div>
    <slot v-else-if="isListEmpty" name="empty-state"></slot>
    <div v-else>
      <registry-list
        :hidden-delete="true"
        :is-loading="isLoading"
        :items="versions"
        :pagination="pageInfo"
        @prev-page="$emit('prev-page')"
        @next-page="$emit('next-page')"
      >
        <template #default="{ item }">
          <version-row :package-entity="item" />
        </template>
      </registry-list>
    </div>
  </div>
</template>
