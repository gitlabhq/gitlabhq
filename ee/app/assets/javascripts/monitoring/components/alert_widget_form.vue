<script>
import { __ } from '~/locale';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

const SUBMIT_ACTION_TEXT = {
  create: __('Add'),
  update: __('Save'),
  delete: __('Delete'),
};

const SUBMIT_BUTTON_CLASS = {
  create: 'btn-create',
  update: 'btn-save',
  delete: 'btn-remove',
};

const OPERATORS = {
  greaterThan: '>',
  equalTo: '=',
  lessThan: '<',
};

export default {
  props: {
    disabled: {
      type: Boolean,
      required: true,
    },
    alert: {
      type: String,
      required: false,
      default: null,
    },
    alertData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      operators: OPERATORS,
      operator: this.alertData.operator,
      threshold: this.alertData.threshold,
    };
  },
  computed: {
    haveValuesChanged() {
      return (
        this.operator &&
        this.threshold === Number(this.threshold) &&
        (this.operator !== this.alertData.operator || this.threshold !== this.alertData.threshold)
      );
    },
    submitAction() {
      if (!this.alert) return 'create';
      if (this.haveValuesChanged) return 'update';
      return 'delete';
    },
    submitActionText() {
      return SUBMIT_ACTION_TEXT[this.submitAction];
    },
    submitButtonClass() {
      return SUBMIT_BUTTON_CLASS[this.submitAction];
    },
    isSubmitDisabled() {
      return this.disabled || (this.submitAction === 'create' && !this.haveValuesChanged);
    },
  },
  watch: {
    alertData() {
      this.resetAlertData();
    },
  },
  methods: {
    handleCancel() {
      this.resetAlertData();
      this.$emit('cancel');
    },
    handleSubmit() {
      this.$refs.submitButton.blur();
      this.$emit(this.submitAction, {
        alert: this.alert,
        operator: this.operator,
        threshold: this.threshold,
      });
    },
    resetAlertData() {
      this.operator = this.alertData.operator;
      this.threshold = this.alertData.threshold;
    },
  },
};
</script>

<template>
  <div class="alert-form">
    <div
      :aria-label="s__('PrometheusAlerts|Operator')"
      class="form-group btn-group"
      role="group"
    >
      <button
        :class="{ active: operator === operators.greaterThan }"
        :disabled="disabled"
        type="button"
        class="btn btn-default"
        @click="operator = operators.greaterThan"
      >
        {{ operators.greaterThan }}
      </button>
      <button
        :class="{ active: operator === operators.equalTo }"
        :disabled="disabled"
        type="button"
        class="btn btn-default"
        @click="operator = operators.equalTo"
      >
        {{ operators.equalTo }}
      </button>
      <button
        :class="{ active: operator === operators.lessThan }"
        :disabled="disabled"
        type="button"
        class="btn btn-default"
        @click="operator = operators.lessThan"
      >
        {{ operators.lessThan }}
      </button>
    </div>
    <div class="form-group">
      <label>{{ s__('PrometheusAlerts|Threshold') }}</label>
      <input
        v-model.number="threshold"
        :disabled="disabled"
        type="number"
        class="form-control"
      />
    </div>
    <div class="action-group">
      <button
        ref="cancelButton"
        :disabled="disabled"
        type="button"
        class="btn btn-default"
        @click="handleCancel"
      >
        {{ __('Cancel') }}
      </button>
      <button
        ref="submitButton"
        :class="submitButtonClass"
        :disabled="isSubmitDisabled"
        type="button"
        class="btn btn-inverted"
        @click="handleSubmit"
      >
        {{ submitActionText }}
      </button>
    </div>
  </div>
</template>
