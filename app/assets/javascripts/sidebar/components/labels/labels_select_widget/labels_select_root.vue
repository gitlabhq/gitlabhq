<script>
import { GlButton, GlCollapsibleListbox, GlDisclosureDropdown, GlLoadingIcon } from '@gitlab/ui';
import issuableLabelsSubscription from 'ee_else_ce/sidebar/queries/issuable_labels.subscription.graphql';
import { mutationOperationMode, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import {
  NAMESPACE_GROUP,
  TYPE_EPIC,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  TYPE_TEST_CASE,
} from '~/issues/constants';
import { __ } from '~/locale';
import { issuableLabelsQueries } from '../../../queries/constants';
import DropdownContents from './dropdown_contents.vue';
import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownValue from './dropdown_value.vue';
import EditToggleButton from './edit_toggle_button.vue';
import EmbeddedLabelsList from './embedded_labels_list.vue';
import groupLabelsQuery from './graphql/group_labels.query.graphql';
import projectLabelsQuery from './graphql/project_labels.query.graphql';
import { VARIANT_SIDEBAR } from './constants';
import {
  isDropdownVariantSidebar,
  isDropdownVariantStandalone,
  isDropdownVariantEmbedded,
} from './utils';

const toItem = (label) => ({ value: label.id, text: label.title, color: label.color });

export default {
  name: 'LabelsSelectRootWidget',
  components: {
    DropdownContents,
    DropdownContentsCreateView,
    DropdownValue,
    EditToggleButton,
    EmbeddedLabelsList,
    GlButton,
    GlCollapsibleListbox,
    GlDisclosureDropdown,
    GlLoadingIcon,
  },
  inject: {
    allowLabelEdit: {
      default: false,
    },
    allowLabelCreate: {
      default: false,
    },
    labelsManagePath: {
      default: '',
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
  emits: ['onLabelRemove', 'toggleCollapse', 'updateSelectedLabels'],
  data() {
    return {
      issuable: null,
      labelsSelectInProgress: false,
      oldIid: null,
      searchTerm: '',
      dropdownOpened: false,
      searchLabels: [],
      selectedLabelsIds: [],
      showLabelForm: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.issuable.loading;
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
    isLabelListEnabled() {
      return this.showEmbeddedLabelsList && isDropdownVariantEmbedded(this.variant);
    },
    isLockOnMergeSupported() {
      return this.issuableSupportsLockOnMerge || this.issuable?.supportsLockOnMerge;
    },
    listboxItems() {
      if (this.searchTerm || !this.issuableLabels.length) {
        return this.searchLabels;
      }

      return [
        { text: __('Selected'), options: this.issuableLabels.map(toItem) },
        {
          text: __('All'),
          textSrOnly: true,
          options: this.searchLabels.filter(
            (label) => !this.issuableLabelIds.includes(label.value),
          ),
        },
      ];
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
        return {
          iid: this.iid,
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.namespace?.issuable;
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
    searchLabels: {
      query() {
        return this.workspaceType === NAMESPACE_GROUP ? groupLabelsQuery : projectLabelsQuery;
      },
      variables() {
        return {
          fullPath: this.attrWorkspacePath,
          searchTerm: this.searchTerm,
        };
      },
      skip() {
        return !this.dropdownOpened;
      },
      update(data) {
        return (data.namespace?.labels?.nodes ?? []).map(toItem);
      },
      debounce: 250,
    },
  },
  watch: {
    iid(_, oldVal) {
      this.oldIid = oldVal;
    },
    issuableLabels: {
      handler(newVal) {
        this.selectedLabelsIds = newVal.map((l) => l.id);
      },
      immediate: true,
    },
  },
  mounted() {
    document.addEventListener('toggleSidebarRevealLabelsDropdown', this.onCollapsedValueClick);
  },
  beforeDestroy() {
    document.removeEventListener('toggleSidebarRevealLabelsDropdown', this.onCollapsedValueClick);
  },
  methods: {
    onShown() {
      this.dropdownOpened = true;
      this.searchTerm = '';
      this.oldIid = null;
    },
    onCollapsedValueClick() {
      this.$emit('toggleCollapse');
      this.$nextTick(() => this.$refs.listbox?.open());
    },
    onSearch(value) {
      this.searchTerm = value;
    },
    onSelect(selectedIds) {
      this.selectedLabelsIds = selectedIds;
      this.searchTerm = '';
      this.$refs.listbox?.$refs.searchBox?.clearInput?.();
    },
    onHidden() {
      const next = this.selectedLabelsIds;
      const current = this.issuableLabelIds;
      const unchanged = next.length === current.length && next.every((id) => current.includes(id));
      if (unchanged) return;
      this.handleDropdownClose(next.map((id) => ({ id })));
    },
    handleLabelCreated(label) {
      this.showLabelForm = false;
      this.selectedLabelsIds = [...this.selectedLabelsIds, label.id];
      this.$nextTick(() => this.$refs.listbox?.open());
    },
    handleDropdownClose(labels) {
      if (this.iid !== '') {
        this.updateSelectedLabels(this.getUpdateVariables(labels));
      } else {
        this.$emit('updateSelectedLabels', { labels });
      }
    },
    getUpdateVariables(labels) {
      const labelIds = labels.map(({ id }) => id);
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
      <div class="hide-collapsed gl-flex gl-font-bold">
        <span>{{ __('Labels') }}</span>
        <gl-loading-icon v-if="isLoading" size="sm" inline class="gl-ml-2" />
        <gl-collapsible-listbox
          v-if="allowLabelEdit && !showLabelForm"
          ref="listbox"
          class="sidebar-dropdown-widget-listbox gl-ml-auto"
          multiple
          searchable
          is-check-centered
          placement="bottom-end"
          :selected="selectedLabelsIds"
          :header-text="labelsListTitle"
          :items="listboxItems"
          :searching="$apollo.queries.searchLabels.loading"
          data-testid="labels-select-dropdown"
          @shown="onShown"
          @search="onSearch"
          @select="onSelect"
          @hidden="onHidden"
        >
          <template #toggle="{ accessibilityAttributes }">
            <edit-toggle-button
              :accessibility-attributes="accessibilityAttributes"
              :loading="labelsSelectInProgress"
            />
          </template>
          <template #list-item="{ item }">
            <div class="gl-flex gl-items-center gl-gap-3 gl-break-anywhere">
              <span
                :style="{ background: item.color }"
                class="gl-border gl-h-3 gl-w-5 gl-shrink-0 gl-rounded-base gl-border-white"
              ></span>
              {{ item.text }}
            </div>
          </template>
          <template #footer>
            <div class="gl-border-t-1 gl-border-t-dropdown gl-p-2 gl-border-t-solid">
              <gl-button
                v-if="allowLabelCreate"
                block
                category="tertiary"
                data-testid="create-label"
                class="!gl-justify-start"
                @click.stop="showLabelForm = true"
                >{{ footerCreateLabelTitle }}</gl-button
              >
              <gl-button
                v-if="labelsManagePath"
                class="!gl-mt-2 !gl-justify-start"
                block
                category="tertiary"
                :href="labelsManagePath"
                data-testid="manage-labels"
                >{{ footerManageLabelTitle }}</gl-button
              >
            </div>
          </template>
        </gl-collapsible-listbox>
        <gl-disclosure-dropdown
          v-else-if="allowLabelEdit && showLabelForm"
          class="sidebar-dropdown-widget-listbox gl-ml-auto"
          block
          start-opened
          @hidden="showLabelForm = false"
        >
          <template #toggle="{ accessibilityAttributes }">
            <edit-toggle-button
              :accessibility-attributes="accessibilityAttributes"
              :loading="labelsSelectInProgress"
            />
          </template>
          <div
            class="gl-border-b gl-mb-4 gl-pb-3 gl-pl-4 gl-pt-2 gl-text-sm gl-font-bold gl-leading-24"
          >
            {{ __('Create label') }}
          </div>
          <dropdown-contents-create-view
            class="gl-mb-2"
            :attr-workspace-path="attrWorkspacePath"
            :full-path="fullPath"
            :label-create-type="labelCreateType"
            :search-key="searchTerm"
            :workspace-type="workspaceType"
            @hideCreateView="showLabelForm = false"
            @labelCreated="handleLabelCreated"
          />
        </gl-disclosure-dropdown>
      </div>

      <dropdown-value
        :disable-labels="labelsSelectInProgress"
        :selected-labels="issuableLabels"
        :allow-label-remove="allowLabelRemove"
        :supports-lock-on-merge="isLockOnMergeSupported"
        :labels-filter-base-path="labelsFilterBasePath"
        :labels-filter-param="labelsFilterParam"
        class="gl-pt-2"
        @onCollapsedValueClick="onCollapsedValueClick"
        @onLabelRemove="handleLabelRemove"
      >
        <slot></slot>
      </dropdown-value>
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
