<script>
import {
  GlLoadingIcon,
  GlSkeletonLoader,
  GlBadge,
  GlSearchBoxByType,
  GlTab,
  GlTabs,
} from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
    GlSkeletonLoader,
    GlBadge,
    GlSearchBoxByType,
    GlTab,
    GlTabs,
  },
  props: {
    i18n: {
      type: Object,
      required: true,
    },
    searchValue: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs>
      <gl-tab :disabled="true">
        <template #title>
          <span>{{ $props.i18n.active }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            <gl-loading-icon label="" size="sm" color="dark" variant="dots" :inline="true" />
          </gl-badge>
        </template>
      </gl-tab>
      <gl-tab :disabled="true">
        <template #title>
          <span>{{ $props.i18n.stopped }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            <gl-loading-icon label="" size="sm" color="dark" variant="dots" :inline="true" />
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <gl-search-box-by-type
      class="gl-mb-4"
      :disabled="true"
      :value="$props.searchValue"
      :placeholder="$props.i18n.searchPlaceholder"
    />
    <div class="gl-pt-6">
      <gl-skeleton-loader :width="1248" :height="200">
        <rect x="8" y="0" width="24" height="24" />
        <rect x="46" y="5" width="247" height="15" />
        <rect x="0" y="49" width="1248" height="1" />

        <rect x="8" y="64" width="24" height="24" />
        <rect x="46" y="69" width="247" height="15" />
        <rect x="0" y="113" width="1248" height="1" />
        <rect x="1168" y="64" width="80" height="32" />

        <rect x="8" y="128" width="24" height="24" />
        <rect x="46" y="133" width="247" height="15" />
        <rect x="0" y="177" width="1248" height="1" />
        <rect x="1168" y="128" width="80" height="32" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
