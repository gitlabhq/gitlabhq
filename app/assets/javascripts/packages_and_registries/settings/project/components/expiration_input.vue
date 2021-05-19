<script>
import { GlFormGroup, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import {
  NAME_REGEX_LENGTH,
  TEXT_AREA_INVALID_FEEDBACK,
} from '~/packages_and_registries/settings/project/constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlSprintf,
    GlLink,
  },
  inject: ['tagsRegexHelpPagePath'],
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: true,
    },
  },
  computed: {
    textAreaLengthErrorMessage() {
      return this.isInputValid(this.value) ? '' : TEXT_AREA_INVALID_FEEDBACK;
    },
    inputValidation() {
      const nameRegexErrors = this.error || this.textAreaLengthErrorMessage;
      return {
        state: nameRegexErrors === null ? null : !nameRegexErrors,
        message: nameRegexErrors,
      };
    },
    internalValue: {
      get() {
        return this.value;
      },
      set(value) {
        this.$emit('input', value);
        this.$emit('validation', this.isInputValid(value));
      },
    },
  },
  methods: {
    isInputValid(value) {
      return !value || value.length <= NAME_REGEX_LENGTH;
    },
  },
};
</script>

<template>
  <gl-form-group
    :id="`${name}-form-group`"
    :label-for="name"
    :state="inputValidation.state"
    :invalid-feedback="inputValidation.message"
  >
    <template #label>
      <span data-testid="label">
        <gl-sprintf :message="label">
          <template #italic="{ content }">
            <i>{{ content }}</i>
          </template>
        </gl-sprintf>
      </span>
    </template>
    <gl-form-input
      :id="name"
      v-model="internalValue"
      :placeholder="placeholder"
      :state="inputValidation.state"
      :disabled="disabled"
      trim
    />
    <template #description>
      <span data-testid="description" class="gl-text-gray-400">
        <gl-sprintf :message="description">
          <template #link="{ content }">
            <gl-link :href="tagsRegexHelpPagePath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </template>
  </gl-form-group>
</template>
