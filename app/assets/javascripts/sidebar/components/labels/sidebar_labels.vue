<script>
import $ from 'jquery';
import { difference, union } from 'lodash';
import flash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

export default {
  components: {
    LabelsSelect,
  },
  variant: DropdownVariant.Sidebar,
  inject: [
    'allowLabelCreate',
    'allowLabelEdit',
    'allowScopedLabels',
    'iid',
    'initiallySelectedLabels',
    'issuableType',
    'labelsFetchPath',
    'labelsManagePath',
    'labelsUpdatePath',
    'projectIssuesPath',
    'projectPath',
  ],
  data() {
    return {
      isLabelsSelectInProgress: false,
      selectedLabels: this.initiallySelectedLabels,
    };
  },
  methods: {
    handleDropdownClose() {
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    handleUpdateSelectedLabels(dropdownLabels) {
      const currentLabelIds = this.selectedLabels.map(label => label.id);
      const userAddedLabelIds = dropdownLabels.filter(label => label.set).map(label => label.id);
      const userRemovedLabelIds = dropdownLabels.filter(label => !label.set).map(label => label.id);

      const labelIds = difference(union(currentLabelIds, userAddedLabelIds), userRemovedLabelIds);

      this.updateSelectedLabels(labelIds);
    },
    handleLabelRemove(labelId) {
      const currentLabelIds = this.selectedLabels.map(label => label.id);
      const labelIds = difference(currentLabelIds, [labelId]);

      this.updateSelectedLabels(labelIds);
    },
    updateSelectedLabels(labelIds) {
      this.isLabelsSelectInProgress = true;

      axios({
        data: {
          [this.issuableType]: {
            label_ids: labelIds,
          },
        },
        method: 'put',
        url: this.labelsUpdatePath,
      })
        .then(({ data }) => {
          this.selectedLabels = data.labels;
        })
        .catch(() => flash(__('An error occurred while updating labels.')))
        .finally(() => {
          this.isLabelsSelectInProgress = false;
        });
    },
  },
};
</script>

<template>
  <labels-select
    class="block labels js-labels-block"
    :allow-label-remove="allowLabelEdit"
    :allow-label-create="allowLabelCreate"
    :allow-label-edit="allowLabelEdit"
    :allow-multiselect="true"
    :allow-scoped-labels="allowScopedLabels"
    :footer-create-label-title="__('Create project label')"
    :footer-manage-label-title="__('Manage project labels')"
    :labels-create-title="__('Create project label')"
    :labels-fetch-path="labelsFetchPath"
    :labels-filter-base-path="projectIssuesPath"
    :labels-manage-path="labelsManagePath"
    :labels-select-in-progress="isLabelsSelectInProgress"
    :selected-labels="selectedLabels"
    :variant="$options.sidebar"
    data-qa-selector="labels_block"
    @onDropdownClose="handleDropdownClose"
    @onLabelRemove="handleLabelRemove"
    @updateSelectedLabels="handleUpdateSelectedLabels"
  >
    {{ __('None') }}
  </labels-select>
</template>
