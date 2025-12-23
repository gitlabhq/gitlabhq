<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemsNewSavedViewModal from './work_items_new_saved_view_modal.vue';

export default {
  name: 'WorkItemsCreateSavedViewDropdown',
  components: {
    GlDisclosureDropdown,
    WorkItemsNewSavedViewModal,
  },
  i18n: {
    addViewButtonText: s__('WorkItem|Add view'),
    newViewTitle: s__('WorkItem|New view'),
    existingViewDropdownTitle: s__('WorkItem|Existing view'),
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
  <div>
    <gl-disclosure-dropdown
      icon="plus"
      category="tertiary"
      :toggle-text="$options.i18n.addViewButtonText"
      no-caret
      left
      :items="dropdownItems"
      data-testid="add-saved-view-toggle"
    />
    <work-items-new-saved-view-modal v-model="isNewViewModalVisible" />
  </div>
</template>
