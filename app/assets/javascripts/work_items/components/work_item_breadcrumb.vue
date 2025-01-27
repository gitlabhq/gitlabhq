<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ROUTES, WORK_ITEM_TYPE_ENUM_EPIC } from '../constants';

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
    isGroup: {
      default: false,
    },
  },
  computed: {
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_ENUM_EPIC;
    },
    listName() {
      if (this.isEpicsList) {
        return __('Epics');
      }

      return this.isGroup ? s__('WorkItem|Work items') : __('Issues');
    },
    issueAsWorkItem() {
      return (
        !this.isGroup &&
        this.glFeatures.workItemsViewPreference &&
        gon.current_user_use_work_items_view &&
        this.glFeatures.workItemsAlpha
      );
    },
    crumbs() {
      const indexCrumb = {
        text: this.listName,
      };

      if (this.glFeatures.workItemEpicsList || this.issueAsWorkItem) {
        indexCrumb.to = { name: ROUTES.index, query: this.$route.query };
      } else {
        indexCrumb.href = this.listPath;
      }

      const crumbs = [indexCrumb];

      if (this.$route.name === ROUTES.new) {
        crumbs.push({
          text: BREADCRUMB_LABELS[ROUTES.new],
          to: ROUTES.new,
        });
      }

      if (this.$route.name === ROUTES.workItem) {
        crumbs.push({
          text: `#${this.$route.params.iid}`,
          to: this.$route.path,
        });
      }

      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="crumbs.length" :items="crumbs" :auto-resize="false" />
</template>
