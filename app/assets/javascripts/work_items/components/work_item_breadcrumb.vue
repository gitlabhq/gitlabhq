<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ROUTES, WORK_ITEM_TYPE_NAME_EPIC } from '../constants';

const BREADCRUMB_LABELS = {
  workItemList: s__('WorkItem|Work items'),
  new: s__('WorkItem|New'),
};

export default {
  components: {
    GlBreadcrumb,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    workItemType: {
      default: null,
    },
    listPath: {
      default: null,
    },
  },
  props: {
    staticBreadcrumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isWorkItemPlanningViewEnabled() {
      return this.glFeatures.workItemPlanningView;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    listName() {
      if (this.isWorkItemPlanningViewEnabled) {
        return s__('WorkItem|Work items');
      }

      if (this.isEpicsList) {
        return __('Epics');
      }

      return __('Issues');
    },
    breadcrumbType() {
      if (this.isWorkItemPlanningViewEnabled) {
        return 'work_items';
      }

      if (this.isEpicsList) {
        return 'epics';
      }

      return 'issues';
    },
    shouldUseRouterNavigation() {
      // NOTE: task are redirected to /issues -> /work_items from BE
      // When clicking breadcrumb, we navigate to the list view using the same path prefix.
      // This redirect users to /work_items in case of "tasks"
      // even if the feature flag is off as we don't show 404 for work_items path when feature flag is off anymore
      const isOnWorkItemsPath = this.$route.path?.includes('work_items');
      if (isOnWorkItemsPath && !this.isWorkItemPlanningViewEnabled) {
        return false;
      }
      return true;
    },
    crumbs() {
      const indexCrumb = {
        text: this.listName,
      };

      if (this.shouldUseRouterNavigation) {
        indexCrumb.to = {
          name: ROUTES.index,
          query: this.$route.query,
          params: { type: this.breadcrumbType },
        };
      } else {
        indexCrumb.href = this.listPath;
      }

      const crumbs = [...this.staticBreadcrumbs, indexCrumb];

      if (this.$route.name === ROUTES.new) {
        crumbs.push({
          text: BREADCRUMB_LABELS[ROUTES.new],
          to: { name: ROUTES.new, params: { type: this.breadcrumbType } },
        });
      }

      if (this.$route.name === ROUTES.workItem) {
        crumbs.push({
          text: `#${this.$route.params.iid}`,
          to: {
            name: ROUTES.workItem,
            params: {
              type: this.$route.params.type,
              iid: this.$route.params.iid,
            },
          },
        });
      }

      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="crumbs.length" :items="crumbs" :auto-resize="true" />
</template>
