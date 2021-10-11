<script>
import createFlash from '~/flash';
import { __ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { labelsQueries } from '~/sidebar/constants';
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
    iid: {
      default: '',
    },
    allowLabelEdit: {
      default: false,
    },
    fullPath: {},
  },
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
    issuableType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      contentIsOnViewport: true,
      issuableLabels: [],
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
  methods: {
    handleDropdownClose(labels) {
      this.$emit('updateSelectedLabels', labels);
      this.collapseEditableItem();
    },
    collapseEditableItem() {
      this.$refs.editable?.collapse();
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
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
      >
        <template #collapsed>
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issuableLabels"
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
            :selected-labels="issuableLabels"
            :allow-label-remove="allowLabelRemove"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-mb-2"
            @onLabelRemove="$emit('onLabelRemove', $event)"
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
            :selected-labels="selectedLabels"
            :variant="variant"
            :issuable-type="issuableType"
            :is-visible="edit"
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
      :selected-labels="selectedLabels"
      :variant="variant"
      :issuable-type="issuableType"
      @setLabels="handleDropdownClose"
    />
  </div>
</template>
