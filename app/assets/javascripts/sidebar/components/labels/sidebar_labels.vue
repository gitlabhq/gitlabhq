<script>
import $ from 'jquery';
import { difference, union } from 'lodash';
import { mapState, mapActions } from 'vuex';
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
  data: () => ({
    labelsSelectInProgress: false,
  }),
  computed: {
    ...mapState(['selectedLabels']),
  },
  mounted() {
    this.setInitialState({
      selectedLabels: this.initiallySelectedLabels,
    });
  },
  methods: {
    ...mapActions(['setInitialState', 'replaceSelectedLabels']),
    handleDropdownClose() {
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    handleUpdateSelectedLabels(labels) {
      const currentLabelIds = this.selectedLabels.map(label => label.id);
      const userAddedLabelIds = labels.filter(label => label.set).map(label => label.id);
      const userRemovedLabelIds = labels.filter(label => !label.set).map(label => label.id);

      const issuableLabels = difference(
        union(currentLabelIds, userAddedLabelIds),
        userRemovedLabelIds,
      );

      this.labelsSelectInProgress = true;

      axios({
        data: {
          [this.issuableType]: {
            label_ids: issuableLabels,
          },
        },
        method: 'put',
        url: this.labelsUpdatePath,
      })
        .then(({ data }) => this.replaceSelectedLabels(data.labels))
        .catch(() => flash(__('An error occurred while updating labels.')))
        .finally(() => {
          this.labelsSelectInProgress = false;
        });
    },
  },
};
</script>

<template>
  <labels-select
    class="block labels js-labels-block"
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
    :labels-select-in-progress="labelsSelectInProgress"
    :selected-labels="selectedLabels"
    :variant="$options.sidebar"
    data-qa-selector="labels_block"
    @onDropdownClose="handleDropdownClose"
    @updateSelectedLabels="handleUpdateSelectedLabels"
  >
    {{ __('None') }}
  </labels-select>
</template>
