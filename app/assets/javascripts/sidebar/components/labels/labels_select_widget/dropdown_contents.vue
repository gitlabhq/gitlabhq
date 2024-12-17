<script>
import { GlButton, GlDropdown, GlDropdownItem, GlLink } from '@gitlab/ui';
import { debounce } from 'lodash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__, sprintf } from '~/locale';
import DropdownContentsCreateView from './dropdown_contents_create_view.vue';
import DropdownContentsLabelsView from './dropdown_contents_labels_view.vue';
import DropdownFooter from './dropdown_footer.vue';
import DropdownHeader from './dropdown_header.vue';
import { isDropdownVariantStandalone, isDropdownVariantSidebar } from './utils';

export default {
  components: {
    DropdownContentsLabelsView,
    DropdownContentsCreateView,
    DropdownHeader,
    DropdownFooter,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlLink,
  },
  inject: {
    toggleAttrs: {
      default: () => ({}),
    },
  },
  props: {
    labelsCreateTitle: {
      type: String,
      required: true,
    },
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowMultiselect: {
      type: Boolean,
      required: true,
    },
    labelsListTitle: {
      type: String,
      required: true,
    },
    dropdownButtonText: {
      type: String,
      required: true,
    },
    footerCreateLabelTitle: {
      type: String,
      required: true,
    },
    footerManageLabelTitle: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: true,
    },
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullPath: {
      type: String,
      required: true,
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
  },
  data() {
    return {
      showDropdownContentsCreateView: false,
      localSelectedLabels: [...this.selectedLabels],
      isDirty: false,
      searchKey: '',
    };
  },
  computed: {
    dropdownContentsView() {
      if (this.showDropdownContentsCreateView) {
        return 'dropdown-contents-create-view';
      }
      return 'dropdown-contents-labels-view';
    },
    dropdownTitle() {
      return this.showDropdownContentsCreateView ? this.labelsCreateTitle : this.labelsListTitle;
    },
    buttonText() {
      if (!this.localSelectedLabels.length) {
        return this.dropdownButtonText || __('Label');
      }
      if (this.localSelectedLabels.length > 1) {
        return sprintf(s__('LabelSelect|%{firstLabelName} +%{remainingLabelCount} more'), {
          firstLabelName: this.localSelectedLabels[0].title,
          remainingLabelCount: this.localSelectedLabels.length - 1,
        });
      }
      return this.localSelectedLabels[0].title;
    },
    showDropdownFooter() {
      return !this.showDropdownContentsCreateView && !this.isStandalone;
    },
    isStandalone() {
      return isDropdownVariantStandalone(this.variant);
    },
    isSidebar() {
      return isDropdownVariantSidebar(this.variant);
    },
  },
  watch: {
    localSelectedLabels: {
      handler() {
        this.isDirty = true;
      },
      deep: true,
    },
    isVisible(newVal) {
      if (newVal) {
        this.$refs.dropdown.show();
        this.isDirty = false;
        this.localSelectedLabels = this.selectedLabels;
      } else {
        this.$refs.dropdown.hide();
        this.setLabels();
      }
    },
    selectedLabels(newVal) {
      if (!this.isDirty || !this.isSidebar) {
        this.localSelectedLabels = newVal;
      }
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  beforeDestroy() {
    this.debouncedSearchKeyUpdate.cancel();
  },
  methods: {
    toggleDropdownContentsCreateView() {
      this.showDropdownContentsCreateView = !this.showDropdownContentsCreateView;
    },
    toggleDropdownContent() {
      this.toggleDropdownContentsCreateView();
      // Required to recalculate dropdown position as its size changes
      if (this.$refs.dropdown?.$refs.dropdown) {
        this.$refs.dropdown.$refs.dropdown.$_popper.scheduleUpdate();
      }
    },
    setLabels() {
      if (!this.isDirty) {
        return;
      }
      this.$emit('setLabels', this.localSelectedLabels);
    },
    handleDropdownHide() {
      this.$emit('closeDropdown');
      if (!this.isSidebar) {
        this.setLabels();
      }
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
    setFocus() {
      this.$refs.header.focusInput();
    },
    hideDropdown() {
      this.$refs.dropdown.hide();
    },
    showDropdown() {
      this.$refs.dropdown.show();
    },
    clearSearch() {
      if (!this.allowMultiselect || this.isStandalone) {
        return;
      }
      this.searchKey = '';
      this.setFocus();
    },
    selectFirstItem() {
      this.$refs.dropdownContentsView.selectFirstItem();
    },
    handleNewLabel(label) {
      this.localSelectedLabels = [...this.localSelectedLabels, label];
      this.toggleDropdownContent();
      this.clearSearch();
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    :text="buttonText"
    block
    data-testid="labels-select-dropdown-contents"
    :toggle-attrs="toggleAttrs"
    @hide="handleDropdownHide"
    @shown="setFocus"
  >
    <template #header>
      <dropdown-header
        ref="header"
        :search-key="searchKey"
        :labels-create-title="labelsCreateTitle"
        :labels-list-title="labelsListTitle"
        :show-dropdown-contents-create-view="showDropdownContentsCreateView"
        :is-standalone="isStandalone"
        @toggleDropdownContentsCreateView="toggleDropdownContent"
        @closeDropdown="hideDropdown"
        @input="debouncedSearchKeyUpdate"
        @searchEnter.prevent="selectFirstItem"
      />
    </template>
    <template #default>
      <component
        :is="dropdownContentsView"
        ref="dropdownContentsView"
        v-model="localSelectedLabels"
        :search-key="searchKey"
        :allow-multiselect="allowMultiselect"
        :full-path="fullPath"
        :workspace-type="workspaceType"
        :attr-workspace-path="attrWorkspacePath"
        :label-create-type="labelCreateType"
        @hideCreateView="toggleDropdownContent"
        @labelCreated="handleNewLabel"
        @input="clearSearch"
      />
    </template>
    <template #footer>
      <dropdown-footer
        v-if="showDropdownFooter"
        :footer-create-label-title="footerCreateLabelTitle"
        :footer-manage-label-title="footerManageLabelTitle"
        @toggleDropdownContentsCreateView="toggleDropdownContent"
      />
    </template>
  </gl-dropdown>
</template>
