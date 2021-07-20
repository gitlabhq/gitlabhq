<script>
import $ from 'jquery';
import Vue from 'vue';
import Vuex, { mapState, mapActions, mapGetters } from 'vuex';
import { isInViewport } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

import { DropdownVariant } from './constants';
import DropdownButton from './dropdown_button.vue';
import DropdownContents from './dropdown_contents.vue';
import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import labelsSelectModule from './store';

Vue.use(Vuex);

export default {
  store: new Vuex.Store(labelsSelectModule()),
  components: {
    DropdownTitle,
    DropdownValue,
    DropdownButton,
    DropdownContents,
    DropdownValueCollapsed,
  },
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
    hideCollapsedView: {
      type: Boolean,
      required: false,
      default: false,
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
    };
  },
  computed: {
    ...mapState(['showDropdownButton', 'showDropdownContents']),
    ...mapGetters([
      'isDropdownVariantSidebar',
      'isDropdownVariantStandalone',
      'isDropdownVariantEmbedded',
    ]),
    dropdownButtonVisible() {
      return this.isDropdownVariantSidebar ? this.showDropdownButton : true;
    },
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
      labelsCreateTitle: this.labelsCreateTitle,
      footerCreateLabelTitle: this.footerCreateLabelTitle,
      footerManageLabelTitle: this.footerManageLabelTitle,
    });

    this.$store.subscribeAction({
      after: this.handleVuexActionDispatch,
    });

    document.addEventListener('mousedown', this.handleDocumentMousedown);
    document.addEventListener('click', this.handleDocumentClick);
  },
  beforeDestroy() {
    document.removeEventListener('mousedown', this.handleDocumentMousedown);
    document.removeEventListener('click', this.handleDocumentClick);
  },
  methods: {
    ...mapActions(['setInitialState', 'toggleDropdownContents']),
    /**
     * This method differentiates between
     * dispatched actions and calls necessary method.
     */
    handleVuexActionDispatch(action, state) {
      if (
        action.type === 'toggleDropdownContents' &&
        !state.showDropdownButton &&
        !state.showDropdownContents
      ) {
        let filterFn = (label) => label.touched;
        if (this.isDropdownVariantEmbedded) {
          filterFn = (label) => label.set;
        }
        this.handleDropdownClose(state.labels.filter(filterFn));
      }
    },
    /**
     * This method stores a mousedown event's target.
     * Required by the click listener because the click
     * event itself has no reference to this element.
     */
    handleDocumentMousedown({ target }) {
      this.mousedownTarget = target;
    },
    /**
     * This method listens for document-wide click event
     * and toggle dropdown if user clicks anywhere outside
     * the dropdown while dropdown is visible.
     */
    handleDocumentClick({ target }) {
      // We also perform the toggle exception check for the
      // last mousedown event's target to avoid hiding the
      // box when the mousedown happened inside the box and
      // only the mouseup did not.
      if (
        this.showDropdownContents &&
        !this.preventDropdownToggleOnClick(target) &&
        !this.preventDropdownToggleOnClick(this.mousedownTarget)
      ) {
        this.toggleDropdownContents();
      }
    },
    /**
     * This method checks whether a given click target
     * should prevent the dropdown from being toggled.
     */
    preventDropdownToggleOnClick(target) {
      // This approach of element detection is needed
      // as the dropdown wrapper is not using `GlDropdown` as
      // it will also require us to use `BDropdownForm`
      // which is yet to be implemented in GitLab UI.
      const hasExceptionClass = [
        'js-dropdown-button',
        'js-btn-cancel-create',
        'js-sidebar-dropdown-toggle',
      ].some(
        (className) =>
          target?.classList.contains(className) ||
          target?.parentElement?.classList.contains(className),
      );

      const hasExceptionParent = ['.js-btn-back', '.js-labels-list'].some(
        (className) => $(target).parents(className).length,
      );

      const isInDropdownButtonCollapsed = this.$refs.dropdownButtonCollapsed?.$el.contains(target);

      const isInDropdownContents = this.$refs.dropdownContents?.$el.contains(target);

      return (
        hasExceptionClass ||
        hasExceptionParent ||
        isInDropdownButtonCollapsed ||
        isInDropdownContents
      );
    },
    handleDropdownClose(labels) {
      // Only emit label updates if there are any labels to update
      // on UI.
      if (labels.length) this.$emit('updateSelectedLabels', labels);
      this.$emit('onDropdownClose');
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
    setContentIsOnViewport(showDropdownContents) {
      if (!showDropdownContents) {
        this.contentIsOnViewport = true;

        return;
      }

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
        v-if="!hideCollapsedView"
        ref="dropdownButtonCollapsed"
        :labels="selectedLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <dropdown-title
        :allow-label-edit="allowLabelEdit"
        :labels-select-in-progress="labelsSelectInProgress"
      />
      <dropdown-value
        :disable-labels="labelsSelectInProgress"
        @onLabelRemove="$emit('onLabelRemove', $event)"
      >
        <slot></slot>
      </dropdown-value>
      <dropdown-button v-show="dropdownButtonVisible" class="gl-mt-2" />
      <dropdown-contents
        v-if="dropdownButtonVisible && showDropdownContents"
        ref="dropdownContents"
        :render-on-top="!contentIsOnViewport"
      />
    </template>
    <template v-if="isDropdownVariantStandalone || isDropdownVariantEmbedded">
      <dropdown-button v-show="dropdownButtonVisible" />
      <dropdown-contents
        v-if="dropdownButtonVisible && showDropdownContents"
        ref="dropdownContents"
        :render-on-top="!contentIsOnViewport"
      />
    </template>
  </div>
</template>
