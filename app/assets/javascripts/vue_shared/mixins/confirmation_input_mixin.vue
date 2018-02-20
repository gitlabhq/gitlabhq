<script>
  import _ from 'underscore';
  import { __, sprintf } from '~/locale';

  export default {
    data() {
      return {
        enteredValue: '',
      };
    },
    computed: {
      id() {
        if (!this.$parent.id) {
          throw new Error('Extending component needs to override this!');
        }
        return `${this.$parent.id}-input`;
      },
      // eslint-disable-next-line vue/return-in-computed-property
      confirmationValue() {
        throw new Error('Extending component needs to override this!');
      },
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
      shouldEscapeConfirmationValue() {
        return true;
      },
    },
    mounted() {
      this.$parent.$on('clearInputs', this.clear);
    },
    beforeDestroy() {
      this.$parent.$off('clearInputs', this.clear);
    },
    created() {
      this.onInput();
    },
    methods: {
      clear() {
        this.enteredValue = '';
      },
      onInput() {
        this.$parent.$emit(
          'toggleCanSubmit',
          this.enteredValue === this.confirmationValue,
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
      :id="id"
      type="text"
      class="form-control"
      v-model="enteredValue"
      @input="onInput"
    />
  </div>
</template>
