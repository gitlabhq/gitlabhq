<script>
import { GlSprintf, GlToggle, GlFormGroup, GlFormInput } from '@gitlab/ui';

import {
  MAVEN_TOGGLE_LABEL,
  MAVEN_TITLE,
  MAVEN_SETTINGS_SUBTITLE,
  MAVEN_DUPLICATES_ALLOWED_DISABLED,
  MAVEN_DUPLICATES_ALLOWED_ENABLED,
  MAVEN_SETTING_EXCEPTION_TITLE,
  MAVEN_SETTINGS_EXCEPTION_LEGEND,
  MAVEN_DUPLICATES_ALLOWED,
  MAVEN_DUPLICATE_EXCEPTION_REGEX,
} from '~/packages_and_registries/settings/group/constants';

export default {
  name: 'MavenSettings',
  i18n: {
    MAVEN_TOGGLE_LABEL,
    MAVEN_TITLE,
    MAVEN_SETTINGS_SUBTITLE,
    MAVEN_SETTING_EXCEPTION_TITLE,
    MAVEN_SETTINGS_EXCEPTION_LEGEND,
  },
  modelNames: {
    MAVEN_DUPLICATES_ALLOWED,
    MAVEN_DUPLICATE_EXCEPTION_REGEX,
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
    mavenDuplicatesAllowed: {
      type: Boolean,
      default: false,
      required: true,
    },
    mavenDuplicateExceptionRegex: {
      type: String,
      default: '',
      required: true,
    },
    mavenDuplicateExceptionRegexError: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    enabledButtonLabel() {
      return this.mavenDuplicatesAllowed
        ? MAVEN_DUPLICATES_ALLOWED_ENABLED
        : MAVEN_DUPLICATES_ALLOWED_DISABLED;
    },
    isMavenDuplicateExceptionRegexValid() {
      return !this.mavenDuplicateExceptionRegexError;
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
  <div>
    <h5 class="gl-border-b-solid gl-border-b-1 gl-border-gray-200">
      {{ $options.i18n.MAVEN_TITLE }}
    </h5>
    <p>{{ $options.i18n.MAVEN_SETTINGS_SUBTITLE }}</p>
    <form>
      <div class="gl-display-flex">
        <gl-toggle
          data-qa-selector="allow_duplicates_toggle"
          :label="$options.i18n.MAVEN_TOGGLE_LABEL"
          label-position="hidden"
          :value="mavenDuplicatesAllowed"
          @change="update($options.modelNames.MAVEN_DUPLICATES_ALLOWED, $event)"
        />
        <div class="gl-ml-5">
          <div data-testid="toggle-label" data-qa-selector="allow_duplicates_label">
            <gl-sprintf :message="enabledButtonLabel">
              <template #bold="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
          </div>
          <gl-form-group
            v-if="!mavenDuplicatesAllowed"
            class="gl-mt-4"
            :label="$options.i18n.MAVEN_SETTING_EXCEPTION_TITLE"
            label-size="sm"
            :state="isMavenDuplicateExceptionRegexValid"
            :invalid-feedback="mavenDuplicateExceptionRegexError"
            :description="$options.i18n.MAVEN_SETTINGS_EXCEPTION_LEGEND"
            label-for="maven-duplicated-settings-regex-input"
          >
            <gl-form-input
              id="maven-duplicated-settings-regex-input"
              :value="mavenDuplicateExceptionRegex"
              @change="update($options.modelNames.MAVEN_DUPLICATE_EXCEPTION_REGEX, $event)"
            />
          </gl-form-group>
        </div>
      </div>
    </form>
  </div>
</template>
