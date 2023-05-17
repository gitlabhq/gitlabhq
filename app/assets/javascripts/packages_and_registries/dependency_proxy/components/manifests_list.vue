<script>
import { GlKeysetPagination, GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import ManifestRow from '~/packages_and_registries/dependency_proxy/components/manifest_row.vue';

export default {
  name: 'ManifestsLists',
  components: {
    ManifestRow,
    GlKeysetPagination,
    GlSkeletonLoader,
  },
  props: {
    manifests: {
      type: Array,
      required: false,
      default: () => [],
    },
    pagination: {
      type: Object,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: () => false,
    },
    dependencyProxyImagePrefix: {
      type: String,
      default: '',
      required: false,
    },
  },
  i18n: {
    listTitle: s__('DependencyProxy|Image list'),
  },
  computed: {
    showPagination() {
      return this.pagination.hasNextPage || this.pagination.hasPreviousPage;
    },
  },
};
</script>

<template>
  <div class="gl-mt-6">
    <h3 class="gl-font-base">{{ $options.i18n.listTitle }}</h3>
    <gl-skeleton-loader v-if="loading" />
    <div v-else data-testid="main-area">
      <div
        class="gl-border-t-1 gl-border-gray-100 gl-border-t-solid gl-display-flex gl-flex-direction-column"
      >
        <manifest-row
          v-for="(manifest, index) in manifests"
          :key="index"
          :dependency-proxy-image-prefix="dependencyProxyImagePrefix"
          :manifest="manifest"
        />
      </div>
      <div class="gl-display-flex gl-justify-content-center">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pagination"
          class="gl-mt-3"
          @prev="$emit('prev-page')"
          @next="$emit('next-page')"
        />
      </div>
    </div>
  </div>
</template>
