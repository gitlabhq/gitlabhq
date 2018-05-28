<script>
import $ from 'jquery';
import { __ } from '~/locale';
import LabelsSelect from '~/labels_select';
import LoadingIcon from '../../loading_icon.vue';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import DropdownButton from './dropdown_button.vue';
import DropdownHiddenInput from './dropdown_hidden_input.vue';
import DropdownHeader from './dropdown_header.vue';
import DropdownSearchInput from './dropdown_search_input.vue';
import DropdownFooter from './dropdown_footer.vue';
import DropdownCreateLabel from './dropdown_create_label.vue';

export default {
  components: {
    LoadingIcon,
    DropdownTitle,
    DropdownValue,
    DropdownValueCollapsed,
    DropdownButton,
    DropdownHiddenInput,
    DropdownHeader,
    DropdownSearchInput,
    DropdownFooter,
    DropdownCreateLabel,
  },
  props: {
    showCreate: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    abilityName: {
      type: String,
      required: true,
    },
    context: {
      type: Object,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
      default: '',
    },
    updatePath: {
      type: String,
      required: false,
      default: '',
    },
    labelsPath: {
      type: String,
      required: true,
    },
    labelsWebUrl: {
      type: String,
      required: false,
      default: '',
    },
    labelFilterBasePath: {
      type: String,
      required: false,
      default: '',
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hiddenInputName() {
      return this.showCreate ? `${this.abilityName}[label_names][]` : 'label_id[]';
    },
    createLabelTitle() {
      if (this.isProject) {
        return __('Create project label');
      }

      return __('Create group label');
    },
    manageLabelsTitle() {
      if (this.isProject) {
        return __('Manage project labels');
      }

      return __('Manage group labels');
    },
  },
  mounted() {
    this.labelsDropdown = new LabelsSelect(this.$refs.dropdownButton, {
      handleClick: this.handleClick,
    });
    $(this.$refs.dropdown).on('hidden.gl.dropdown', this.handleDropdownHidden);
  },
  methods: {
    handleClick(label) {
      this.$emit('onLabelClick', label);
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
    handleDropdownHidden() {
      this.$emit('onDropdownClose');
    },
  },
};
</script>

<template>
  <div class="block labels js-labels-block">
    <dropdown-value-collapsed
      v-if="showCreate"
      :labels="context.labels"
      @onValueClick="handleCollapsedValueClick"
    />
    <dropdown-title
      :can-edit="canEdit"
    />
    <dropdown-value
      :labels="context.labels"
      :label-filter-base-path="labelFilterBasePath"
    >
      <slot></slot>
    </dropdown-value>
    <div
      v-if="canEdit"
      class="selectbox js-selectbox"
      style="display: none;"
    >
      <dropdown-hidden-input
        v-for="label in context.labels"
        :key="label.id"
        :name="hiddenInputName"
        :label="label"
      />
      <div
        class="dropdown"
        ref="dropdown"
      >
        <dropdown-button
          :ability-name="abilityName"
          :field-name="hiddenInputName"
          :update-path="updatePath"
          :labels-path="labelsPath"
          :namespace="namespace"
          :labels="context.labels"
          :show-extra-options="!showCreate"
        />
        <div
          class="dropdown-menu dropdown-select dropdown-menu-paging
dropdown-menu-labels dropdown-menu-selectable"
        >
          <div class="dropdown-page-one">
            <dropdown-header v-if="showCreate" />
            <dropdown-search-input/>
            <div class="dropdown-content"></div>
            <div class="dropdown-loading">
              <loading-icon />
            </div>
            <dropdown-footer
              v-if="showCreate"
              :labels-web-url="labelsWebUrl"
              :create-label-title="createLabelTitle"
              :manage-labels-title="manageLabelsTitle"
            />
          </div>
          <dropdown-create-label
            v-if="showCreate"
            :is-project="isProject"
            :header-title="createLabelTitle"
          />
        </div>
      </div>
    </div>
  </div>
</template>
