<script>
import { GlForm } from '@gitlab/ui';
import WorkItemBulkEditLabels from './work_item_bulk_edit_labels.vue';

export default {
  components: {
    GlForm,
    WorkItemBulkEditLabels,
  },
  props: {
    checkedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      addLabelIds: [],
      removeLabelIds: [],
    };
  },
  methods: {
    handleFormSubmitted() {
      this.$emit('bulk-update', {
        ids: this.checkedItems.map((item) => item.id),
        addLabelIds: this.addLabelIds,
        removeLabelIds: this.removeLabelIds,
      });
      this.addLabelIds = [];
      this.removeLabelIds = [];
    },
  },
};
</script>

<template>
  <gl-form id="work-item-list-bulk-edit" class="gl-p-5" @submit.prevent="handleFormSubmitted">
    <work-item-bulk-edit-labels
      :form-label="__('Add labels')"
      form-label-id="bulk-update-add-labels"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="addLabelIds"
      @select="addLabelIds = $event"
    />
    <work-item-bulk-edit-labels
      :checked-items="checkedItems"
      :form-label="__('Remove labels')"
      form-label-id="bulk-update-remove-labels"
      :full-path="fullPath"
      :is-group="isGroup"
      :selected-labels-ids="removeLabelIds"
      @select="removeLabelIds = $event"
    />
  </gl-form>
</template>
