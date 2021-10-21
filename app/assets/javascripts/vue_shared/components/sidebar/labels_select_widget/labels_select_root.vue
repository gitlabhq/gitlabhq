<script>
import { MutationOperationMode } from '~/graphql_shared/utils';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { __ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { labelsQueries, labelsMutations } from '~/sidebar/constants';
import { DropdownVariant } from './constants';
import DropdownContents from './dropdown_contents.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import {
  isDropdownVariantSidebar,
  isDropdownVariantStandalone,
  isDropdownVariantEmbedded,
} from './utils';

export default {
  components: {
    DropdownValue,
    DropdownContents,
    DropdownValueCollapsed,
    SidebarEditableItem,
  },
  inject: {
    allowLabelEdit: {
      default: false,
    },
  },
  props: {
    iid: {
      type: String,
      required: false,
      default: '',
    },
    fullPath: {
      type: String,
      required: true,
    },
    allowLabelRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowMultiselect: {
      type: Boolean,
      required: false,
      default: false,
    },
    variant: {
      type: String,
      required: false,
      default: DropdownVariant.Sidebar,
    },
    labelsFilterBasePath: {
      type: String,
      required: false,
      default: '',
    },
    labelsFilterParam: {
      type: String,
      required: false,
      default: 'label_name',
    },
    dropdownButtonText: {
      type: String,
      required: false,
      default: __('Label'),
    },
    labelsListTitle: {
      type: String,
      required: false,
      default: __('Assign labels'),
    },
    labelsCreateTitle: {
      type: String,
      required: false,
      default: __('Create group label'),
    },
    footerCreateLabelTitle: {
      type: String,
      required: false,
      default: __('Create group label'),
    },
    footerManageLabelTitle: {
      type: String,
      required: false,
      default: __('Manage group labels'),
    },
    issuableType: {
      type: String,
      required: true,
    },
    attrWorkspacePath: {
      type: String,
      required: true,
    },
    labelType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      contentIsOnViewport: true,
      issuableLabels: [],
      labelsSelectInProgress: false,
      oldIid: null,
    };
  },
  computed: {
    isLoading() {
      return this.labelsSelectInProgress || this.$apollo.queries.issuableLabels.loading;
    },
  },
  apollo: {
    issuableLabels: {
      query() {
        return labelsQueries[this.issuableType].issuableQuery;
      },
      skip() {
        return !isDropdownVariantSidebar(this.variant);
      },
      variables() {
        return {
          iid: this.iid,
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.issuable?.labels.nodes || [];
      },
      error() {
        createFlash({ message: __('Error fetching labels.') });
      },
    },
  },
  watch: {
    iid(_, oldVal) {
      this.oldIid = oldVal;
    },
  },
  methods: {
    handleDropdownClose(labels) {
      if (this.iid !== '') {
        this.updateSelectedLabels(this.getUpdateVariables(labels));
      } else {
        this.$emit('updateSelectedLabels', { labels });
      }

      this.collapseEditableItem();
    },
    collapseEditableItem() {
      this.$refs.editable?.collapse();
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
    getUpdateVariables(labels) {
      let labelIds = [];

      labelIds = labels.map(({ id }) => id);
      const currentIid = this.oldIid || this.iid;

      const updateVariables = {
        iid: currentIid,
        projectPath: this.fullPath,
        labelIds,
      };

      switch (this.issuableType) {
        case IssuableType.Issue:
          return updateVariables;
        case IssuableType.MergeRequest:
          updateVariables.operationMode = MutationOperationMode.Replace;
          return updateVariables;
        default:
          return {};
      }
    },
    updateSelectedLabels(inputVariables) {
      this.labelsSelectInProgress = true;

      this.$apollo
        .mutate({
          mutation: labelsMutations[this.issuableType].mutation,
          variables: { input: inputVariables },
        })
        .then(({ data }) => {
          const { mutationName } = labelsMutations[this.issuableType];

          if (data[mutationName]?.errors?.length) {
            throw new Error();
          }

          this.$emit('updateSelectedLabels', {
            id: data[mutationName]?.[this.issuableType].id,
            labels: data[mutationName]?.[this.issuableType].labels?.nodes,
          });
        })
        .catch((error) =>
          createFlash({
            message: __('An error occurred while updating labels.'),
            captureError: true,
            error,
          }),
        )
        .finally(() => {
          this.labelsSelectInProgress = false;
        });
    },
    getRemoveVariables(labelId) {
      const removeVariables = {
        iid: this.iid,
        projectPath: this.fullPath,
      };

      switch (this.issuableType) {
        case IssuableType.Issue:
          return {
            ...removeVariables,
            removeLabelIds: [labelId],
          };
        case IssuableType.MergeRequest:
          return {
            ...removeVariables,
            labelIds: [labelId],
            operationMode: MutationOperationMode.Remove,
          };
        default:
          return {};
      }
    },
    handleLabelRemove(labelId) {
      this.updateSelectedLabels(this.getRemoveVariables(labelId));
      this.$emit('onLabelRemove', labelId);
    },
    isDropdownVariantSidebar,
    isDropdownVariantStandalone,
    isDropdownVariantEmbedded,
  },
};
</script>

<template>
  <div
    class="labels-select-wrapper position-relative"
    :class="{
      'is-standalone': isDropdownVariantStandalone(variant),
      'is-embedded': isDropdownVariantEmbedded(variant),
    }"
  >
    <template v-if="isDropdownVariantSidebar(variant)">
      <dropdown-value-collapsed
        ref="dropdownButtonCollapsed"
        :labels="issuableLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <sidebar-editable-item
        ref="editable"
        :title="__('Labels')"
        :loading="isLoading"
        :can-edit="allowLabelEdit"
        @open="oldIid = null"
      >
        <template #collapsed>
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issuableLabels"
            :allow-label-remove="allowLabelRemove"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            @onLabelRemove="handleLabelRemove"
          >
            <slot></slot>
          </dropdown-value>
        </template>
        <template #default="{ edit }">
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issuableLabels"
            :allow-label-remove="allowLabelRemove"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-mb-2"
            @onLabelRemove="handleLabelRemove"
          >
            <slot></slot>
          </dropdown-value>
          <dropdown-contents
            :dropdown-button-text="dropdownButtonText"
            :allow-multiselect="allowMultiselect"
            :labels-list-title="labelsListTitle"
            :footer-create-label-title="footerCreateLabelTitle"
            :footer-manage-label-title="footerManageLabelTitle"
            :labels-create-title="labelsCreateTitle"
            :selected-labels="issuableLabels"
            :variant="variant"
            :issuable-type="issuableType"
            :is-visible="edit"
            :full-path="fullPath"
            :attr-workspace-path="attrWorkspacePath"
            :label-type="labelType"
            @setLabels="handleDropdownClose"
            @closeDropdown="collapseEditableItem"
          />
        </template>
      </sidebar-editable-item>
    </template>
    <dropdown-contents
      v-else
      ref="dropdownContents"
      :allow-multiselect="allowMultiselect"
      :dropdown-button-text="dropdownButtonText"
      :labels-list-title="labelsListTitle"
      :footer-create-label-title="footerCreateLabelTitle"
      :footer-manage-label-title="footerManageLabelTitle"
      :labels-create-title="labelsCreateTitle"
      :selected-labels="issuableLabels"
      :variant="variant"
      :issuable-type="issuableType"
      :full-path="fullPath"
      :attr-workspace-path="attrWorkspacePath"
      :label-type="labelType"
      @setLabels="handleDropdownClose"
    />
  </div>
</template>
