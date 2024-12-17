<script>
import { debounce } from 'lodash';
import issuableLabelsSubscription from 'ee_else_ce/sidebar/queries/issuable_labels.subscription.graphql';
import { mutationOperationMode, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST, TYPE_TEST_CASE } from '~/issues/constants';

import { __ } from '~/locale';
import { keysFor, ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { issuableLabelsQueries } from '../../../queries/constants';
import SidebarEditableItem from '../../sidebar_editable_item.vue';
import { DEBOUNCE_DROPDOWN_DELAY, VARIANT_SIDEBAR } from './constants';
import DropdownContents from './dropdown_contents.vue';
import DropdownValue from './dropdown_value.vue';
import EmbeddedLabelsList from './embedded_labels_list.vue';
import {
  isDropdownVariantSidebar,
  isDropdownVariantStandalone,
  isDropdownVariantEmbedded,
} from './utils';

export default {
  components: {
    DropdownValue,
    DropdownContents,
    EmbeddedLabelsList,
    SidebarEditableItem,
  },
  mixins: [glFeatureFlagsMixin()],
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
    showEmbeddedLabelsList: {
      type: Boolean,
      required: false,
      default: false,
    },
    variant: {
      type: String,
      required: false,
      default: VARIANT_SIDEBAR,
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
      default: __('Select labels'),
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
    issuableSupportsLockOnMerge: {
      type: Boolean,
      required: false,
      default: false,
    },
    workspaceType: {
      type: String,
      required: true,
    },
    attrWorkspacePath: {
      type: String,
      required: true,
    },
    labelCreateType: {
      type: String,
      required: true,
    },
    selectedLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      contentIsOnViewport: true,
      issuable: null,
      labelsSelectInProgress: false,
      oldIid: null,
      sidebarExpandedOnClick: false,
    };
  },
  computed: {
    isLoading() {
      return this.labelsSelectInProgress || this.$apollo.queries.issuable.loading;
    },
    issuableLabelIds() {
      return this.issuableLabels.map((label) => label.id);
    },
    issuableLabels() {
      if (this.iid !== '') {
        return this.issuable?.labels.nodes || [];
      }

      return this.selectedLabels || [];
    },
    issuableId() {
      return this.issuable?.id;
    },
    isRealtimeEnabled() {
      return this.glFeatures.realtimeLabels;
    },
    isLabelListEnabled() {
      return this.showEmbeddedLabelsList && isDropdownVariantEmbedded(this.variant);
    },
    isLockOnMergeSupported() {
      return this.issuableSupportsLockOnMerge || this.issuable?.supportsLockOnMerge;
    },
    labelShortcutDescription() {
      return shouldDisableShortcuts() ? null : ISSUABLE_CHANGE_LABEL.description;
    },
    labelShortcutKey() {
      return shouldDisableShortcuts() ? null : keysFor(ISSUABLE_CHANGE_LABEL)[0];
    },
    labelTooltip() {
      const description = this.labelShortcutDescription;
      const key = this.labelShortcutKey;
      return shouldDisableShortcuts()
        ? null
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>${key}</kbd>`);
    },
  },
  apollo: {
    issuable: {
      query() {
        return issuableLabelsQueries[this.issuableType].issuableQuery;
      },
      skip() {
        return !isDropdownVariantSidebar(this.variant) || !this.iid;
      },
      variables() {
        const queryVariables = {
          iid: this.iid,
          fullPath: this.fullPath,
        };

        if (this.issuableType === TYPE_TEST_CASE) {
          queryVariables.types = ['TEST_CASE'];
        }

        return queryVariables;
      },
      update(data) {
        return data.workspace?.issuable;
      },
      error() {
        createAlert({ message: __('Error fetching labels.') });
      },
      subscribeToMore: {
        document() {
          return issuableLabelsSubscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return !this.issuableId || !this.isDropdownVariantSidebar;
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { issuableLabelsUpdated },
            },
          },
        ) {
          if (issuableLabelsUpdated) {
            const {
              id,
              labels: { nodes },
            } = issuableLabelsUpdated;
            this.$emit('updateSelectedLabels', { id, labels: nodes });
          }
        },
      },
    },
  },
  watch: {
    iid(_, oldVal) {
      this.oldIid = oldVal;
    },
  },
  mounted() {
    document.addEventListener('toggleSidebarRevealLabelsDropdown', this.handleCollapsedValueClick);
  },
  beforeDestroy() {
    document.removeEventListener(
      'toggleSidebarRevealLabelsDropdown',
      this.handleCollapsedValueClick,
    );
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
      if (this.sidebarExpandedOnClick) {
        this.sidebarExpandedOnClick = false;
        this.$emit('toggleCollapse');
      }
    },
    handleCollapsedValueClick() {
      this.sidebarExpandedOnClick = true;
      this.$emit('toggleCollapse');
      debounce(() => {
        this.$refs.editable.toggle();
        this.$refs.dropdownContents.showDropdown();
      }, DEBOUNCE_DROPDOWN_DELAY)();
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
        case TYPE_ISSUE:
        case TYPE_TEST_CASE:
          return updateVariables;
        case TYPE_MERGE_REQUEST:
          return {
            ...updateVariables,
            operationMode: mutationOperationMode.replace,
          };
        case TYPE_EPIC:
          return {
            iid: currentIid,
            groupPath: this.fullPath,
            addLabelIds: labelIds.map((id) => getIdFromGraphQLId(id)),
            removeLabelIds: this.issuableLabelIds
              .filter((id) => !labelIds.includes(id))
              .map((id) => getIdFromGraphQLId(id)),
          };
        default:
          return {};
      }
    },
    updateSelectedLabels(inputVariables) {
      this.labelsSelectInProgress = true;

      this.$apollo
        .mutate({
          mutation: issuableLabelsQueries[this.issuableType].mutation,
          variables: { input: inputVariables },
        })
        .then(({ data }) => {
          if (data.updateIssuableLabels?.errors?.length) {
            throw new Error();
          }

          this.$emit('updateSelectedLabels', {
            id: data.updateIssuableLabels?.issuable?.id,
            labels: data.updateIssuableLabels?.issuable?.labels?.nodes,
          });
        })
        .catch((error) =>
          createAlert({
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
        case TYPE_ISSUE:
        case TYPE_TEST_CASE:
          return {
            ...removeVariables,
            removeLabelIds: [labelId],
          };
        case TYPE_MERGE_REQUEST:
          return {
            ...removeVariables,
            labelIds: [labelId],
            operationMode: mutationOperationMode.remove,
          };
        case TYPE_EPIC:
          return {
            iid: this.iid,
            removeLabelIds: [getIdFromGraphQLId(labelId)],
            groupPath: this.fullPath,
          };
        default:
          return {};
      }
    },
    handleLabelRemove(labelId) {
      if (this.iid !== '') {
        this.updateSelectedLabels(this.getRemoveVariables(labelId));
      }

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
    class="labels-select-wrapper gl-relative"
    :class="{
      'is-standalone': isDropdownVariantStandalone(variant),
      'is-embedded': isDropdownVariantEmbedded(variant),
    }"
    data-testid="sidebar-labels"
  >
    <template v-if="isDropdownVariantSidebar(variant)">
      <sidebar-editable-item
        ref="editable"
        :title="__('Labels')"
        :edit-tooltip="labelTooltip"
        :edit-aria-label="labelShortcutDescription"
        :edit-keyshortcuts="labelShortcutKey"
        :loading="isLoading"
        :can-edit="allowLabelEdit"
        @open="oldIid = null"
      >
        <template #collapsed>
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issuableLabels"
            :allow-label-remove="allowLabelRemove"
            :supports-lock-on-merge="isLockOnMergeSupported"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-pt-2"
            @onLabelRemove="handleLabelRemove"
            @onCollapsedValueClick="handleCollapsedValueClick"
          >
            <slot></slot>
          </dropdown-value>
        </template>
        <template #default="{ edit }">
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issuableLabels"
            :allow-label-remove="allowLabelRemove"
            :supports-lock-on-merge="isLockOnMergeSupported"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-mb-2"
            @onLabelRemove="handleLabelRemove"
          >
            <slot></slot>
          </dropdown-value>
          <dropdown-contents
            ref="dropdownContents"
            class="gl-mt-3 gl-w-full"
            :dropdown-button-text="dropdownButtonText"
            :allow-multiselect="allowMultiselect"
            :labels-list-title="labelsListTitle"
            :footer-create-label-title="footerCreateLabelTitle"
            :footer-manage-label-title="footerManageLabelTitle"
            :labels-create-title="labelsCreateTitle"
            :selected-labels="issuableLabels"
            :variant="variant"
            :is-visible="edit"
            :full-path="fullPath"
            :workspace-type="workspaceType"
            :attr-workspace-path="attrWorkspacePath"
            :label-create-type="labelCreateType"
            @setLabels="handleDropdownClose"
            @closeDropdown="collapseEditableItem"
          />
        </template>
      </sidebar-editable-item>
    </template>
    <template v-else>
      <dropdown-contents
        ref="dropdownContents"
        class="issuable-form-select-holder"
        :dropdown-button-text="dropdownButtonText"
        :allow-multiselect="allowMultiselect"
        :labels-list-title="labelsListTitle"
        :footer-create-label-title="footerCreateLabelTitle"
        :footer-manage-label-title="footerManageLabelTitle"
        :labels-create-title="labelsCreateTitle"
        :selected-labels="issuableLabels"
        :variant="variant"
        :full-path="fullPath"
        :workspace-type="workspaceType"
        :attr-workspace-path="attrWorkspacePath"
        :label-create-type="labelCreateType"
        @setLabels="handleDropdownClose"
      />
      <embedded-labels-list
        v-if="isLabelListEnabled"
        :disabled="labelsSelectInProgress"
        :selected-labels="issuableLabels"
        :allow-label-remove="allowLabelRemove"
        :supports-lock-on-merge="isLockOnMergeSupported"
        :labels-filter-base-path="labelsFilterBasePath"
        :labels-filter-param="labelsFilterParam"
        @onLabelRemove="handleLabelRemove"
      />
    </template>
  </div>
</template>
