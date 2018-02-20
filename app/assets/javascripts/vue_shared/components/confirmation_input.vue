<script>
  import _ from 'underscore';
  import { __, sprintf } from '~/locale';

  export default {
    props: {
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
      onInput(event) {
        const input = event.target;
        this.$emit(
          'confirmed',
          input.value === this.confirmationValue,
        );
      },
    },
  };
</script>

<template>
  <div>
    <label>
      <span v-html="inputLabel"></span>
      <input
        type="text"
        class="form-control"
        @input="onInput"
      />
    </label>
  </div>
</template>
