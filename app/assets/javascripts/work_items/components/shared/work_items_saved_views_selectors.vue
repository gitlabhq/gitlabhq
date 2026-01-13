<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemsCreateSavedViewDropdown from '../work_items_create_saved_view_dropdown.vue';

export default {
  name: 'WorkItemsSavedViewsSelectors',
  components: {
    GlTabs,
    GlTab,
    WorkItemsCreateSavedViewDropdown,
  },
  i18n: {
    defaultViewtitle: s__('WorkItem|All items'),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="saved-views-selectors gl-border-b gl-flex gl-flex-row gl-flex-nowrap gl-justify-between"
  >
    <gl-tabs class="gl-m-0 gl-flex gl-items-center gl-p-0">
      <gl-tab>
        <template #title>
          <span data-testid="saved-views-default-view-selector">{{
            $options.i18n.defaultViewtitle
          }}</span>
        </template>
      </gl-tab>
      <work-items-create-saved-view-dropdown :full-path="fullPath" />
    </gl-tabs>
    <div class="!gl-flex gl-items-center gl-justify-end gl-gap-3">
      <slot name="header-area"></slot>
    </div>
  </div>
</template>
