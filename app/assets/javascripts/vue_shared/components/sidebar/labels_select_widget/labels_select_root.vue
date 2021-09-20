<script>
import Vue from 'vue';
import Vuex from 'vuex';
import { __ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { DropdownVariant } from './constants';
import DropdownContents from './dropdown_contents.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import issueLabelsQuery from './graphql/issue_labels.query.graphql';
import {
  isDropdownVariantSidebar,
  isDropdownVariantStandalone,
  isDropdownVariantEmbedded,
} from './utils';

Vue.use(Vuex);

export default {
  components: {
    DropdownValue,
    DropdownContents,
    DropdownValueCollapsed,
    SidebarEditableItem,
  },
  inject: ['iid', 'projectPath', 'allowLabelEdit'],
  props: {
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
    selectedLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
    labelsSelectInProgress: {
      type: Boolean,
      required: false,
      default: false,
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
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      contentIsOnViewport: true,
      issueLabels: [],
    };
  },
  apollo: {
    issueLabels: {
      query: issueLabelsQuery,
      variables() {
        return {
          iid: this.iid,
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.workspace?.issuable?.labels.nodes || [];
      },
    },
  },
  methods: {
    handleDropdownClose(labels) {
      if (labels.length) this.$emit('updateSelectedLabels', labels);
      this.$emit('onDropdownClose');
    },
    collapseDropdown() {
      this.$refs.editable.collapse();
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
    showDropdown() {
      this.$nextTick(() => {
        this.$refs.dropdownContents.showDropdown();
      });
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
        :labels="issueLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <sidebar-editable-item
        ref="editable"
        :title="__('Labels')"
        :loading="labelsSelectInProgress"
        :can-edit="allowLabelEdit"
        @open="showDropdown"
      >
        <template #collapsed>
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issueLabels"
            :allow-label-remove="allowLabelRemove"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            @onLabelRemove="$emit('onLabelRemove', $event)"
          >
            <slot></slot>
          </dropdown-value>
        </template>
        <template #default="{ edit }">
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issueLabels"
            :allow-label-remove="allowLabelRemove"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-mb-2"
            @onLabelRemove="$emit('onLabelRemove', $event)"
          >
            <slot></slot>
          </dropdown-value>
          <dropdown-contents
            v-if="edit"
            ref="dropdownContents"
            :dropdown-button-text="dropdownButtonText"
            :allow-multiselect="allowMultiselect"
            :labels-list-title="labelsListTitle"
            :footer-create-label-title="footerCreateLabelTitle"
            :footer-manage-label-title="footerManageLabelTitle"
            :labels-create-title="labelsCreateTitle"
            :selected-labels="selectedLabels"
            :variant="variant"
            @closeDropdown="collapseDropdown"
            @setLabels="handleDropdownClose"
          />
        </template>
      </sidebar-editable-item>
    </template>
  </div>
</template>
