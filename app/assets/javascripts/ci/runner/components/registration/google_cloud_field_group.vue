<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'GoogleCloudField',
  components: {
    GlFormGroup,
    GlFormInput,
  },
  model: {
    prop: 'value',
    event: 'change',
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: () => ({ value: '', state: null }),
      validator: ({ value }) => typeof value === 'string',
    },
    invalidFeedbackIfEmpty: {
      type: String,
      required: false,
      default: __('This field is required.'),
    },
    invalidFeedbackIfMalformed: {
      type: String,
      required: false,
      default: __('This value is not valid.'),
    },
    regexp: {
      type: RegExp,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      state: null,
      invalidFeedback: '',
    };
  },
  methods: {
    onChange(value) {
      if (!value) {
        this.state = false;
        this.invalidFeedback = this.invalidFeedbackIfEmpty;
      } else if (this.regexp && !value.match(this.regexp)) {
        this.state = false;
        this.invalidFeedback = this.invalidFeedbackIfMalformed;
      } else {
        this.state = true;
        this.invalidFeedback = '';
      }
      this.$emit('change', { state: this.state, value });
    },
  },
};
</script>
<template>
  <gl-form-group
    :label-for="name"
    :state="state"
    :invalid-feedback="invalidFeedback"
    :label="label"
  >
    <template v-for="slot in Object.keys($scopedSlots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
    <gl-form-input
      :id="name"
      :name="name"
      :state="state"
      :value="value ? value.value : ''"
      type="text"
      @change="onChange"
    />
  </gl-form-group>
</template>
