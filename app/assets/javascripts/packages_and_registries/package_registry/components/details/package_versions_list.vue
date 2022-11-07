<script>
import { GlKeysetPagination } from '@gitlab/ui';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';

export default {
  components: {
    VersionRow,
    GlKeysetPagination,
    PackagesListLoader,
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
    showPagination() {
      return this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage;
    },
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
      <version-row v-for="version in versions" :key="version.id" :package-entity="version" />
      <div class="gl-display-flex gl-justify-content-center">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          class="gl-mt-3"
          @prev="$emit('prev-page')"
          @next="$emit('next-page')"
        />
      </div>
    </div>
  </div>
</template>
