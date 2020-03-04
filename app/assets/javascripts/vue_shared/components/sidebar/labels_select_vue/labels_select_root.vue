<script>
import Vue from 'vue';
import Vuex, { mapState, mapActions } from 'vuex';
import { __ } from '~/locale';

import DropdownValueCollapsed from '~/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed.vue';

import labelsSelectModule from './store';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownButton from './dropdown_button.vue';
import DropdownContents from './dropdown_contents.vue';

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
    allowLabelEdit: {
      type: Boolean,
      required: true,
    },
    allowLabelCreate: {
      type: Boolean,
      required: true,
    },
    allowScopedLabels: {
      type: Boolean,
      required: true,
    },
    dropdownOnly: {
      type: Boolean,
      required: false,
      default: false,
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
    scopedLabelsDocumentationPath: {
      type: String,
      required: false,
      default: '',
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
  },
  computed: {
    ...mapState(['showDropdownButton', 'showDropdownContents']),
  },
  watch: {
    selectedLabels(selectedLabels) {
      this.setInitialState({
        selectedLabels,
      });
    },
  },
  mounted() {
    this.setInitialState({
      dropdownOnly: this.dropdownOnly,
      allowLabelEdit: this.allowLabelEdit,
      allowLabelCreate: this.allowLabelCreate,
      allowScopedLabels: this.allowScopedLabels,
      selectedLabels: this.selectedLabels,
      labelsFetchPath: this.labelsFetchPath,
      labelsManagePath: this.labelsManagePath,
      labelsFilterBasePath: this.labelsFilterBasePath,
      scopedLabelsDocumentationPath: this.scopedLabelsDocumentationPath,
      labelsListTitle: this.labelsListTitle,
      labelsCreateTitle: this.labelsCreateTitle,
      footerCreateLabelTitle: this.footerCreateLabelTitle,
      footerManageLabelTitle: this.footerManageLabelTitle,
    });

    this.$store.subscribeAction({
      after: this.handleVuexActionDispatch,
    });
  },
  methods: {
    ...mapActions(['setInitialState']),
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
        this.handleDropdownClose(state.labels.filter(label => label.touched));
      }
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
  },
};
</script>

<template>
  <div class="labels-select-wrapper position-relative">
    <div v-if="!dropdownOnly">
      <dropdown-value-collapsed
        v-if="allowLabelCreate"
        :labels="selectedLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <dropdown-title
        :allow-label-edit="allowLabelEdit"
        :labels-select-in-progress="labelsSelectInProgress"
      />
      <dropdown-value v-show="!showDropdownButton">
        <slot></slot>
      </dropdown-value>
      <dropdown-button v-show="showDropdownButton" />
      <dropdown-contents v-if="showDropdownButton && showDropdownContents" />
    </div>
  </div>
</template>
