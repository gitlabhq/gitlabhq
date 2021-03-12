<script>
import { GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import { CI_CONFIG_STATUS_VALID } from '../../constants';

export const i18n = {
  empty: __(
    "We'll continuously validate your pipeline configuration. The validation results will appear here.",
  ),
  learnMore: __('Learn more'),
  loading: s__('Pipelines|Validating GitLab CI configuration…'),
  invalid: s__('Pipelines|This GitLab CI configuration is invalid.'),
  invalidWithReason: s__('Pipelines|This GitLab CI configuration is invalid: %{reason}.'),
  valid: s__('Pipelines|This GitLab CI configuration is valid.'),
};

export default {
  i18n,
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
    TooltipOnTruncate,
  },
  inject: {
    ymlHelpPagePath: {
      default: '',
    },
  },
  props: {
    ciFileContent: {
      type: String,
      required: true,
    },
    ciConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isEmpty() {
      return !this.ciFileContent;
    },
    isValid() {
      return this.ciConfig?.status === CI_CONFIG_STATUS_VALID;
    },
    icon() {
      if (this.isValid || this.isEmpty) {
        return 'check';
      }
      return 'warning-solid';
    },
    message() {
      if (this.isEmpty) {
        return this.$options.i18n.empty;
      } else if (this.isValid) {
        return this.$options.i18n.valid;
      }

      // Only display first error as a reason
      const [reason] = this.ciConfig?.errors || [];
      if (reason) {
        return sprintf(this.$options.i18n.invalidWithReason, { reason }, false);
      }
      return this.$options.i18n.invalid;
    },
  },
};
</script>

<template>
  <div>
    <template v-if="loading">
      <gl-loading-icon inline />
      {{ $options.i18n.loading }}
    </template>

    <span v-else class="gl-display-inline-flex gl-white-space-nowrap gl-max-w-full">
      <tooltip-on-truncate :title="message" class="gl-text-truncate">
        <gl-icon :name="icon" /> <span data-testid="validationMsg">{{ message }}</span>
      </tooltip-on-truncate>
      <span v-if="!isEmpty" class="gl-flex-shrink-0 gl-pl-2">
        <gl-link data-testid="learnMoreLink" :href="ymlHelpPagePath">
          {{ $options.i18n.learnMore }}
        </gl-link>
      </span>
    </span>
  </div>
</template>
