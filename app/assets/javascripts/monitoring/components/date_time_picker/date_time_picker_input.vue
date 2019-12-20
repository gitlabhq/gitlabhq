<script>
import _ from 'underscore';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { dateFormats } from '~/monitoring/constants';

const inputGroupText = {
  invalidFeedback: sprintf(s__('Format: %{dateFormat}'), {
    dateFormat: dateFormats.dateTimePicker.format,
  }),
  placeholder: dateFormats.dateTimePicker.format,
};

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    state: {
      default: null,
      required: true,
      validator: prop => typeof prop === 'boolean' || prop === null,
    },
    value: {
      default: null,
      required: false,
      validator: prop => typeof prop === 'string' || prop === null,
    },
    label: {
      type: String,
      default: '',
      required: true,
    },
    id: {
      type: String,
      required: false,
      default: () => _.uniqueId('dateTimePicker_'),
    },
  },
  data() {
    return {
      inputGroupText,
    };
  },
  computed: {
    invalidFeedback() {
      return this.state ? '' : this.inputGroupText.invalidFeedback;
    },
    inputState() {
      // When the state is valid we want to show no
      // green outline. Hence passing null and not true.
      if (this.state === true) {
        return null;
      }
      return this.state;
    },
  },
  methods: {
    onInputBlur(e) {
      this.$emit('input', e.target.value.trim() || null);
    },
  },
};
</script>

<template>
  <gl-form-group :label="label" label-size="sm" :label-for="id" :invalid-feedback="invalidFeedback">
    <gl-form-input
      :id="id"
      :value="value"
      :state="inputState"
      :placeholder="inputGroupText.placeholder"
      @blur="onInputBlur"
    />
  </gl-form-group>
</template>
