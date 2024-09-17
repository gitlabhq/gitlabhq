<script>
import { GlBadge, GlTab, GlTabs, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { SCOPE } from '../../constants';

export default {
  components: {
    GlBadge,
    GlTab,
    GlTabs,
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    resourceCounts: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tabs() {
      return [
        {
          text: s__('CiCatalog|All'),
          scope: SCOPE.all,
          testId: 'resources-all-tab',
          count: this.resourceCounts.all,
        },
        {
          text: s__('CiCatalog|Your groups'),
          scope: SCOPE.namespaces,
          testId: 'resources-group-tab',
          count: this.resourceCounts.namespaces,
        },
      ];
    },
    showLoadingIcon() {
      return this.isLoading;
    },
  },
};
</script>

<template>
  <div class="align-items-lg-center gl-flex">
    <gl-tabs content-class="gl-py-0" class="gl-w-full">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.text"
        :data-testid="tab.testId"
        @click="$emit('setScope', tab.scope)"
      >
        <template #title>
          <span>{{ tab.text }}</span>
          <gl-loading-icon v-if="showLoadingIcon" class="gl-ml-3" />

          <gl-badge v-else class="gl-tab-counter-badge">
            {{ tab.count }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
