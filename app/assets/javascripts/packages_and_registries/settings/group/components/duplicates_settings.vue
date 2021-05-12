<script>
import { GlSprintf, GlToggle, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { isEqual } from 'lodash';

import {
  DUPLICATES_TOGGLE_LABEL,
  DUPLICATES_ALLOWED_DISABLED,
  DUPLICATES_ALLOWED_ENABLED,
  DUPLICATES_SETTING_EXCEPTION_TITLE,
  DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
} from '~/packages_and_registries/settings/group/constants';

export default {
  name: 'DuplicatesSettings',
  i18n: {
    DUPLICATES_TOGGLE_LABEL,
    DUPLICATES_SETTING_EXCEPTION_TITLE,
    DUPLICATES_SETTINGS_EXCEPTION_LEGEND,
  },
  components: {
    GlSprintf,
    GlToggle,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    duplicatesAllowed: {
      type: Boolean,
      default: false,
      required: false,
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
    modelNames: {
      type: Object,
      required: true,
      validator(value) {
        return isEqual(Object.keys(value), ['allowed', 'exception']);
      },
    },
    toggleQaSelector: {
      type: String,
      required: false,
      default: null,
    },
    labelQaSelector: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    enabledButtonLabel() {
      return this.duplicatesAllowed ? DUPLICATES_ALLOWED_ENABLED : DUPLICATES_ALLOWED_DISABLED;
    },
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
  <form>
    <div class="gl-display-flex">
      <gl-toggle
        :data-qa-selector="toggleQaSelector"
        :label="$options.i18n.DUPLICATES_TOGGLE_LABEL"
        label-position="hidden"
        :value="duplicatesAllowed"
        @change="update(modelNames.allowed, $event)"
      />
      <div class="gl-ml-5">
        <div data-testid="toggle-label" :data-qa-selector="labelQaSelector">
          <gl-sprintf :message="enabledButtonLabel">
            <template #bold="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </div>
        <gl-form-group
          v-if="!duplicatesAllowed"
          class="gl-mt-4"
          :label="$options.i18n.DUPLICATES_SETTING_EXCEPTION_TITLE"
          label-size="sm"
          :state="isExceptionRegexValid"
          :invalid-feedback="duplicateExceptionRegexError"
          :description="$options.i18n.DUPLICATES_SETTINGS_EXCEPTION_LEGEND"
          label-for="maven-duplicated-settings-regex-input"
        >
          <gl-form-input
            id="maven-duplicated-settings-regex-input"
            :value="duplicateExceptionRegex"
            @change="update(modelNames.exception, $event)"
          />
        </gl-form-group>
      </div>
    </div>
  </form>
</template>
