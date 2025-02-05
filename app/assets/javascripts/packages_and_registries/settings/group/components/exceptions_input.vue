<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import {
  DUPLICATES_SETTING_EXCEPTION_TITLE,
  DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
} from '~/packages_and_registries/settings/group/constants';

export default {
  name: 'ExceptionsInput',
  i18n: {
    DUPLICATES_SETTING_EXCEPTION_TITLE,
    DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
  },
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    duplicateExceptionRegex: {
      type: String,
      default: '',
      required: false,
    },
    duplicateExceptionRegexError: {
      type: String,
      default: '',
      required: false,
    },
    id: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
  },
  computed: {
    isExceptionRegexValid() {
      return !this.duplicateExceptionRegexError;
    },
  },
  methods: {
    update(type, value) {
      this.$emit('update', { [type]: value });
    },
  },
};
</script>

<template>
  <gl-form-group
    class="gl-mb-0"
    :label="$options.i18n.DUPLICATES_SETTING_EXCEPTION_TITLE"
    label-sr-only
    :invalid-feedback="duplicateExceptionRegexError"
    :label-for="id"
  >
    <gl-form-input
      :id="id"
      :disabled="loading"
      width="lg"
      :value="duplicateExceptionRegex"
      :state="isExceptionRegexValid"
      @change="update(name, $event)"
    />
  </gl-form-group>
</template>
