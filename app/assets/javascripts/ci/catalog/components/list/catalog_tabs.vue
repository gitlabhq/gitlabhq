<script>
import { GlBadge, GlTab, GlTabs, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { SCOPE, MIN_ACCESS_LEVEL, TAB_NAME } from '~/ci/catalog/constants';

export default {
  name: 'CatalogTabs',
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
  emits: ['tab-change'],
  computed: {
    tabs() {
      return [
        {
          text: s__('CiCatalog|All'),
          scope: SCOPE.all,
          testId: 'resources-all-tab',
          count: this.resourceCounts.all,
          name: TAB_NAME.all,
        },
        {
          text: s__('CiCatalog|Your groups'),
          scope: SCOPE.namespaces,
          testId: 'resources-group-tab',
          count: this.resourceCounts.namespaces,
          name: TAB_NAME.namespaces,
        },
        {
          text: s__('CiCatalog|Analytics'),
          scope: SCOPE.namespaces,
          testId: 'resources-analytics-tab',
          count: this.resourceCounts.analytics,
          minAccessLevel: MIN_ACCESS_LEVEL,
          name: TAB_NAME.analytics,
        },
      ];
    },
    showLoadingIcon() {
      return this.isLoading;
    },
  },
  methods: {
    onTabChange(tab) {
      this.$emit('tab-change', {
        name: tab.name,
        scope: tab.scope,
        minAccessLevel: tab.minAccessLevel,
      });
    },
  },
};
</script>

<template>
  <div class="gl-flex @lg/panel:gl-items-center">
    <gl-tabs content-class="gl-py-0" class="gl-w-full">
      <gl-tab
        v-for="tab in tabs"
        :key="tab.text"
        :data-testid="tab.testId"
        @click="onTabChange(tab)"
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
