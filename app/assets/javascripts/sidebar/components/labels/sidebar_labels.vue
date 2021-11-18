<script>
import $ from 'jquery';
import { camelCase, difference, union } from 'lodash';
import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import createFlash from '~/flash';
import { getIdFromGraphQLId, MutationOperationMode } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
import { __ } from '~/locale';
import updateMergeRequestLabelsMutation from '~/sidebar/queries/update_merge_request_labels.mutation.graphql';
import { toLabelGid } from '~/sidebar/utils';
import { DropdownVariant } from '~/vue_shared/components/sidebar/labels_select_vue/constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import LabelsSelectWidget from '~/vue_shared/components/sidebar/labels_select_widget/labels_select_root.vue';
import { LabelType } from '~/vue_shared/components/sidebar/labels_select_widget/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const mutationMap = {
  [IssuableType.Issue]: {
    mutation: updateIssueLabelsMutation,
    mutationName: 'updateIssue',
  },
  [IssuableType.MergeRequest]: {
    mutation: updateMergeRequestLabelsMutation,
    mutationName: 'mergeRequestSetLabels',
  },
};

export default {
  components: {
    LabelsSelect,
    LabelsSelectWidget,
  },
  variant: DropdownVariant.Sidebar,
  mixins: [glFeatureFlagMixin()],
  inject: [
    'allowLabelCreate',
    'allowLabelEdit',
    'allowScopedLabels',
    'iid',
    'fullPath',
    'initiallySelectedLabels',
    'issuableType',
    'labelsFetchPath',
    'labelsManagePath',
    'projectIssuesPath',
    'projectPath',
  ],
  data() {
    return {
      isLabelsSelectInProgress: false,
      selectedLabels: this.initiallySelectedLabels,
      LabelType,
    };
  },
  methods: {
    handleDropdownClose() {
      $(this.$el).trigger('hidden.gl.dropdown');
    },
    getUpdateVariables(labels) {
      let labelIds = [];

      if (this.glFeatures.labelsWidget) {
        labelIds = labels.map(({ id }) => toLabelGid(id));
      } else {
        const currentLabelIds = this.selectedLabels.map((label) => label.id);
        const userAddedLabelIds = labels.filter((label) => label.set).map((label) => label.id);
        const userRemovedLabelIds = labels.filter((label) => !label.set).map((label) => label.id);

        labelIds = difference(union(currentLabelIds, userAddedLabelIds), userRemovedLabelIds).map(
          toLabelGid,
        );
      }

      switch (this.issuableType) {
        case IssuableType.Issue:
          return {
            iid: this.iid,
            projectPath: this.projectPath,
            labelIds,
          };
        case IssuableType.MergeRequest:
          return {
            iid: this.iid,
            labelIds,
            operationMode: MutationOperationMode.Replace,
            projectPath: this.projectPath,
          };
        default:
          return {};
      }
    },
    handleUpdateSelectedLabels(dropdownLabels) {
      this.updateSelectedLabels(this.getUpdateVariables(dropdownLabels));
    },
    getRemoveVariables(labelId) {
      switch (this.issuableType) {
        case IssuableType.Issue:
          return {
            iid: this.iid,
            projectPath: this.projectPath,
            removeLabelIds: [labelId],
          };
        case IssuableType.MergeRequest:
          return {
            iid: this.iid,
            labelIds: [toLabelGid(labelId)],
            operationMode: MutationOperationMode.Remove,
            projectPath: this.projectPath,
          };
        default:
          return {};
      }
    },
    handleLabelRemove(labelId) {
      this.updateSelectedLabels(this.getRemoveVariables(labelId));
    },
    updateSelectedLabels(inputVariables) {
      this.isLabelsSelectInProgress = true;

      this.$apollo
        .mutate({
          mutation: mutationMap[this.issuableType].mutation,
          variables: { input: inputVariables },
        })
        .then(({ data }) => {
          const { mutationName } = mutationMap[this.issuableType];

          if (data[mutationName]?.errors?.length) {
            throw new Error();
          }

          const issuableType = camelCase(this.issuableType);
          this.selectedLabels = data[mutationName]?.[issuableType]?.labels?.nodes?.map((label) => ({
            ...label,
            id: getIdFromGraphQLId(label.id),
          }));
        })
        .catch(() => createFlash({ message: __('An error occurred while updating labels.') }))
        .finally(() => {
          this.isLabelsSelectInProgress = false;
        });
    },
  },
};
</script>

<template>
  <labels-select-widget
    v-if="glFeatures.labelsWidget"
    class="block labels js-labels-block"
    :iid="iid"
    :full-path="fullPath"
    :allow-label-remove="allowLabelEdit"
    :allow-multiselect="true"
    :footer-create-label-title="__('Create project label')"
    :footer-manage-label-title="__('Manage project labels')"
    :labels-create-title="__('Create project label')"
    :labels-filter-base-path="projectIssuesPath"
    :variant="$options.variant"
    :issuable-type="issuableType"
    workspace-type="project"
    :attr-workspace-path="fullPath"
    :label-create-type="LabelType.project"
    data-qa-selector="labels_block"
  >
    {{ __('None') }}
  </labels-select-widget>
  <labels-select
    v-else
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
