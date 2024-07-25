<script>
import { GlFormGroup } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import LabelsSelect from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import { __ } from '~/locale';

export default {
  components: {
    GlFormGroup,
    LabelsSelect,
  },
  inject: [
    'allowLabelRemove',
    'attrWorkspacePath',
    'fieldName',
    'fullPath',
    'labelsFilterBasePath',
    'initialLabels',
    'issuableType',
    'labelType',
    'issuableSupportsLockOnMerge',
    'variant',
    'workspaceType',
  ],
  data() {
    return {
      selectedLabels: this.initialLabels || [],
    };
  },
  methods: {
    handleUpdateSelectedLabels({ labels }) {
      this.selectedLabels = labels.map((label) => ({ ...label, id: getIdFromGraphQLId(label.id) }));
    },
    handleLabelRemove(labelId) {
      this.selectedLabels = this.selectedLabels.filter((label) => label.id !== labelId);
    },
  },
  i18n: {
    fieldLabel: __('Labels'),
    dropdownButtonText: __('Select label'),
    listTitle: __('Select label'),
    createTitle: __('Create project label'),
    manageTitle: __('Manage project labels'),
    emptySelection: __('None'),
  },
};
</script>

<template>
  <gl-form-group class="row" label-class="gl-hidden">
    <label class="col-12 gl-align-center gl-flex">
      {{ $options.i18n.fieldLabel }}
    </label>
    <div class="col-12">
      <div class="issuable-form-label-select-holder">
        <input
          v-for="selectedLabel in selectedLabels"
          :key="selectedLabel.id"
          :value="selectedLabel.id"
          :name="fieldName"
          type="hidden"
        />
        <labels-select
          class="block labels"
          :allow-label-remove="allowLabelRemove"
          :allow-multiselect="true"
          :show-embedded-labels-list="true"
          :full-path="fullPath"
          :attr-workspace-path="attrWorkspacePath"
          :labels-filter-base-path="labelsFilterBasePath"
          :dropdown-button-text="$options.i18n.dropdownButtonText"
          :labels-list-title="$options.i18n.listTitle"
          :footer-create-label-title="$options.i18n.createTitle"
          :footer-manage-label-title="$options.i18n.manageTitle"
          :variant="variant"
          :workspace-type="workspaceType"
          :issuable-type="issuableType"
          :label-create-type="labelType"
          :selected-labels="selectedLabels"
          :issuable-supports-lock-on-merge="issuableSupportsLockOnMerge"
          @updateSelectedLabels="handleUpdateSelectedLabels"
          @onLabelRemove="handleLabelRemove"
        >
          {{ $options.i18n.emptySelection }}
        </labels-select>
      </div>
    </div>
  </gl-form-group>
</template>
