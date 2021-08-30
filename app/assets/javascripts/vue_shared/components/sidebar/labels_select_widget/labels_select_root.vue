<script>
import Vue from 'vue';
import Vuex, { mapState, mapActions, mapGetters } from 'vuex';
import { isInViewport } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import { DropdownVariant } from './constants';
import DropdownButton from './dropdown_button.vue';
import DropdownContents from './dropdown_contents.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import issueLabelsQuery from './graphql/issue_labels.query.graphql';
import labelsSelectModule from './store';

Vue.use(Vuex);

export default {
  store: new Vuex.Store(labelsSelectModule()),
  components: {
    DropdownValue,
    DropdownButton,
    DropdownContents,
    DropdownValueCollapsed,
    SidebarEditableItem,
  },
  inject: ['iid', 'projectPath'],
  props: {
    allowLabelRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowLabelEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowLabelCreate: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowMultiselect: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowScopedLabels: {
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
    labelsFetchPath: {
      type: String,
      required: false,
      default: '',
    },
    labelsManagePath: {
      type: String,
      required: false,
      default: '',
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
  computed: {
    ...mapState(['showDropdownContents']),
    ...mapGetters([
      'isDropdownVariantSidebar',
      'isDropdownVariantStandalone',
      'isDropdownVariantEmbedded',
    ]),
  },
  watch: {
    selectedLabels(selectedLabels) {
      this.setInitialState({
        selectedLabels,
      });
    },
    showDropdownContents(showDropdownContents) {
      this.setContentIsOnViewport(showDropdownContents);
    },
    isEditing(newVal) {
      if (newVal) {
        this.toggleDropdownContents();
      }
    },
  },
  mounted() {
    this.setInitialState({
      variant: this.variant,
      allowLabelRemove: this.allowLabelRemove,
      allowLabelEdit: this.allowLabelEdit,
      allowLabelCreate: this.allowLabelCreate,
      allowMultiselect: this.allowMultiselect,
      allowScopedLabels: this.allowScopedLabels,
      dropdownButtonText: this.dropdownButtonText,
      selectedLabels: this.selectedLabels,
      labelsFetchPath: this.labelsFetchPath,
      labelsManagePath: this.labelsManagePath,
      labelsFilterBasePath: this.labelsFilterBasePath,
      labelsFilterParam: this.labelsFilterParam,
      labelsListTitle: this.labelsListTitle,
      footerCreateLabelTitle: this.footerCreateLabelTitle,
      footerManageLabelTitle: this.footerManageLabelTitle,
    });
  },
  methods: {
    ...mapActions(['setInitialState']),
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
    setContentIsOnViewport() {
      this.$nextTick(() => {
        if (this.$refs.dropdownContents) {
          this.contentIsOnViewport = isInViewport(this.$refs.dropdownContents.$el);
        }
      });
    },
  },
};
</script>

<template>
  <div
    class="labels-select-wrapper position-relative"
    :class="{
      'is-standalone': isDropdownVariantStandalone,
      'is-embedded': isDropdownVariantEmbedded,
    }"
  >
    <template v-if="isDropdownVariantSidebar">
      <dropdown-value-collapsed
        ref="dropdownButtonCollapsed"
        :labels="issueLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <sidebar-editable-item
        ref="editable"
        :title="__('Labels')"
        :loading="labelsSelectInProgress"
        @open="setContentIsOnViewport"
        @close="contentIsOnViewport = true"
      >
        <template #collapsed>
          <dropdown-value
            :disable-labels="labelsSelectInProgress"
            :selected-labels="issueLabels"
            :allow-label-remove="allowLabelRemove"
            :allow-scoped-labels="allowScopedLabels"
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
            :allow-scoped-labels="allowScopedLabels"
            :labels-filter-base-path="labelsFilterBasePath"
            :labels-filter-param="labelsFilterParam"
            class="gl-mb-2"
            @onLabelRemove="$emit('onLabelRemove', $event)"
          >
            <slot></slot>
          </dropdown-value>
          <dropdown-button />
          <dropdown-contents
            v-if="edit"
            ref="dropdownContents"
            :allow-multiselect="allowMultiselect"
            :labels-list-title="labelsListTitle"
            :footer-create-label-title="footerCreateLabelTitle"
            :footer-manage-label-title="footerManageLabelTitle"
            :render-on-top="!contentIsOnViewport"
            :labels-create-title="labelsCreateTitle"
            :selected-labels="selectedLabels"
            @closeDropdown="collapseDropdown"
            @setLabels="handleDropdownClose"
          />
        </template>
      </sidebar-editable-item>
    </template>
  </div>
</template>
