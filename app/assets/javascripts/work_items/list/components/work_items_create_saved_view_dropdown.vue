<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemsNewSavedViewModal from './work_items_new_saved_view_modal.vue';
import WorkItemsExistingSavedViewsModal from './work_items_existing_saved_views_modal.vue';

export default {
  name: 'WorkItemsCreateSavedViewDropdown',
  components: {
    GlDisclosureDropdown,
    WorkItemsNewSavedViewModal,
    WorkItemsExistingSavedViewsModal,
  },
  i18n: {
    addViewButtonText: s__('WorkItem|Add view'),
    newViewTitle: s__('WorkItem|New view'),
    existingViewDropdownTitle: s__('WorkItem|Browse views'),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isNewViewModalVisible: false,
      isExistingViewModalVisible: false,
    };
  },
  computed: {
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.newViewTitle,
          action: () => {
            this.isNewViewModalVisible = true;
          },
        },
        {
          text: this.$options.i18n.existingViewDropdownTitle,
          action: () => {
            this.isExistingViewModalVisible = true;
          },
        },
      ];
    },
  },
};
</script>

<template>
  <div class="gl-self-center">
    <gl-disclosure-dropdown
      icon="plus"
      category="tertiary"
      :toggle-text="$options.i18n.addViewButtonText"
      no-caret
      left
      :items="dropdownItems"
      data-testid="add-saved-view-toggle"
    />
    <work-items-new-saved-view-modal
      v-model="isNewViewModalVisible"
      :full-path="fullPath"
      :sort-key="sortKey"
      @hide="isNewViewModalVisible = false"
    />
    <work-items-existing-saved-views-modal
      v-model="isExistingViewModalVisible"
      :full-path="fullPath"
      @show-new-view-modal="isNewViewModalVisible = true"
    />
  </div>
</template>
