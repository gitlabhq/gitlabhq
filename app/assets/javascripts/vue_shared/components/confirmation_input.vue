<script>
  import _ from 'underscore';
  import { __, sprintf } from '~/locale';

  export default {
    props: {
      inputId: {
        type: String,
        required: true,
      },
      confirmationKey: {
        type: String,
        required: true,
      },
      confirmationValue: {
        type: String,
        required: true,
      },
      shouldEscapeConfirmationValue: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    computed: {
      inputLabel() {
        let value = this.confirmationValue;
        if (this.shouldEscapeConfirmationValue) {
          value = _.escape(value);
        }

        return sprintf(
          __('Type %{value} to confirm:'),
          { value: `<code>${value}</code>` },
          false,
        );
      },
    },
    methods: {
      hasCorrectValue() {
        return this.$refs.enteredValue.value === this.confirmationValue;
      },
    },
  };
</script>

<template>
  <div>
    <label
      v-html="inputLabel"
      :for="inputId"
    >
    </label>
    <input
      :id="inputId"
      :name="confirmationKey"
      type="text"
      ref="enteredValue"
      class="form-control"
    />
  </div>
</template>
