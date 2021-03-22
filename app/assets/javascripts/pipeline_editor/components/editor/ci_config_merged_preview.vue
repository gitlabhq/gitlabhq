<script>
import { GlAlert, GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, s__ } from '~/locale';
import { DEFAULT, INVALID_CI_CONFIG } from '~/pipelines/constants';
import EditorLite from '~/vue_shared/components/editor_lite.vue';

export default {
  i18n: {
    viewOnlyMessage: s__('Pipelines|Merged YAML is view only'),
  },
  errorTexts: {
    [INVALID_CI_CONFIG]: __('Your CI configuration file is invalid.'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  components: {
    EditorLite,
    GlAlert,
    GlIcon,
  },
  inject: ['ciConfigPath'],
  props: {
    isValid: {
      type: Boolean,
      required: true,
    },
    ciConfigData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      failureType: null,
    };
  },
  computed: {
    failure() {
      switch (this.failureType) {
        case INVALID_CI_CONFIG:
          return this.$options.errorTexts[INVALID_CI_CONFIG];
        default:
          return this.$options.errorTexts[DEFAULT];
      }
    },
    fileGlobalId() {
      return `${this.ciConfigPath}-${uniqueId()}`;
    },
    hasError() {
      return this.failureType;
    },
    mergedYaml() {
      return this.ciConfigData.mergedYaml;
    },
  },
  watch: {
    ciConfigData: {
      immediate: true,
      handler() {
        if (!this.isValid) {
          this.reportFailure(INVALID_CI_CONFIG);
        } else if (this.hasError) {
          this.resetFailure();
        }
      },
    },
  },
  methods: {
    reportFailure(errorType) {
      this.failureType = errorType;
    },
    resetFailure() {
      this.failureType = null;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="hasError" variant="danger" :dismissible="false">
      {{ failure }}
    </gl-alert>
    <div v-else>
      <div class="gl-display-flex gl-align-items-center">
        <gl-icon :size="16" name="lock" class="gl-text-gray-500 gl-mr-3" />
        {{ $options.i18n.viewOnlyMessage }}
      </div>
      <div class="gl-mt-3 gl-border-solid gl-border-gray-100 gl-border-1">
        <editor-lite
          ref="editor"
          :value="mergedYaml"
          :file-name="ciConfigPath"
          :file-global-id="fileGlobalId"
          :editor-options="{ readOnly: true }"
          v-on="$listeners"
        />
      </div>
    </div>
  </div>
</template>
