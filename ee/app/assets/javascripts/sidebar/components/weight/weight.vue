<script>
import $ from 'jquery';
import { s__ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import tooltip from '~/vue_shared/directives/tooltip';
import icon from '~/vue_shared/components/icon.vue';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';

export default {
  components: {
    icon,
    loadingIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    fetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    weight: {
      type: [String, Number],
      required: false,
      default: '',
    },
    weightNoneValue: {
      type: String,
      required: true,
      default: 'None',
    },
    editable: {
      type: Boolean,
      required: false,
      default: false,
    },
    id: {
      type: [String, Number],
      required: false,
      default: '',
    },
  },
  data() {
    return {
      hasValidInput: true,
      shouldShowEditField: false,
      collapsedAfterUpdate: false,
    };
  },
  computed: {
    isNoValue() {
      return this.checkIfNoValue(this.weight);
    },
    collapsedWeightLabel() {
      let label = this.weight;
      if (this.checkIfNoValue(this.weight)) {
        label = this.noValueLabel;
      }

      // Truncate with ellipsis after five digits
      if (this.weight > 99999) {
        label = `${this.weight.toString().substr(0, 5)}&hellip;`;
      }

      return label;
    },
    noValueLabel() {
      return s__('Sidebar|None');
    },
    changeWeightLabel() {
      return s__('Sidebar|Change weight');
    },
    dropdownToggleLabel() {
      let label = this.weight;
      if (this.checkIfNoValue(this.weight)) {
        label = s__('Sidebar|Weight');
      }

      return label;
    },
    shouldShowWeight() {
      return !this.fetching && !this.shouldShowEditField;
    },
    tooltipTitle() {
      let tooltipTitle = s__('Sidebar|Weight');

      if (!this.checkIfNoValue(this.weight)) {
        tooltipTitle += ` ${this.weight}`;
      }

      return tooltipTitle;
    },
  },
  methods: {
    checkIfNoValue(weight) {
      return weight === undefined || weight === null || weight === this.weightNoneValue;
    },
    showEditField(bool = true) {
      this.shouldShowEditField = bool;

      if (this.shouldShowEditField) {
        this.$nextTick(() => {
          this.$refs.editableField.focus();
        });
      }
    },
    onCollapsedClick() {
      this.showEditField(true);
      this.collapsedAfterUpdate = true;
    },
    onSubmit(e) {
      const { value } = e.target;
      const validatedValue = Number(value);
      const isNewValue = validatedValue !== this.weight;

      this.hasValidInput = validatedValue >= 0 || value === '';

      if (!this.loading && this.hasValidInput) {
        $(this.$el).trigger('hidden.gl.dropdown');

        if (isNewValue) {
          eventHub.$emit('updateWeight', value, this.id);
        }

        this.showEditField(false);
      }
    },
    removeWeight() {
      eventHub.$emit('updateWeight', '', this.id);
    },
  },
};
</script>

<template>
  <div
    class="block weight"
    :class="{ 'collapse-after-update': collapsedAfterUpdate }"
  >
    <div
      class="sidebar-collapsed-icon js-weight-collapsed-block"
      v-tooltip
      data-container="body"
      data-placement="left"
      data-boundary="viewport"
      :title="tooltipTitle"
      @click="onCollapsedClick"
    >
      <icon
        name="scale"
        :size="16"
      />
      <loading-icon
        v-if="fetching"
        class="js-weight-collapsed-loading-icon"
      />
      <span
        v-else
        v-html="collapsedWeightLabel"
        class="js-weight-collapsed-weight-label"
      ></span>
    </div>
    <div class="title hide-collapsed">
      {{ s__('Sidebar|Weight') }}
      <loading-icon
        v-if="fetching || loading"
        :inline="true"
        class="js-weight-loading-icon"
      />
      <a
        v-if="editable"
        class="float-right js-weight-edit-link"
        href="#"
        @click="showEditField(!shouldShowEditField)"
      >
        {{ __('Edit') }}
      </a>
    </div>
    <div
      class="hide-collapsed"
      v-if="shouldShowEditField"
    >
      <input
        class="form-control"
        type="text"
        ref="editableField"
        :value="weight"
        @blur="onSubmit"
        @keydown.enter="onSubmit"
      />
      <span
        class="gl-field-error"
        v-if="!hasValidInput"
      >
        <icon
          name="merge-request-close-m"
          :size="24"
        />
        {{ s__('Sidebar|Only numeral characters allowed') }}
      </span>
    </div>
    <div
      v-if="shouldShowWeight"
      class="value hide-collapsed js-weight-weight-label"
    >
      <span v-if="!isNoValue">
        <strong class="js-weight-weight-label-value">{{ weight }}</strong>
        &nbsp;-&nbsp;
        <a
          v-if="editable"
          class="btn-default-hover-link js-weight-remove-link"
          href="#"
          @click="removeWeight"
        >
          {{ __('remove weight') }}
        </a>
      </span>
      <span
        v-else
        class="no-value">
        {{ noValueLabel }}
      </span>
    </div>
  </div>
</template>
