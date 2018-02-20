<script>
  import _ from 'underscore';
  import { __, sprintf } from '~/locale';

  export default {
    props: {
      id: {
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
    mounted() {
      this.$on('clear', this.clear);
    },
    beforeDestroy() {
      this.$off('clear', this.clear);
    },
    methods: {
      clear() {
        this.$refs.input.value = '';
        this.$emit('confirmed', '' === this.confirmationValue);
      },
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
    <label
      v-html="inputLabel"
      :for="id"></label>
    <input
      ref="input"
      :id="id"
      type="text"
      class="form-control"
      @input="onInput"
    />
  </div>
</template>
