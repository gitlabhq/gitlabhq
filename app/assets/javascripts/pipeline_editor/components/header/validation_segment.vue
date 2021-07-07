<script>
import { GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import getAppStatus from '~/pipeline_editor/graphql/queries/client/app_status.graphql';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import {
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
} from '../../constants';

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
    ciConfig: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  apollo: {
    appStatus: {
      query: getAppStatus,
    },
  },
  computed: {
    isEmpty() {
      return this.appStatus === EDITOR_APP_STATUS_EMPTY;
    },
    isLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
    isValid() {
      return this.appStatus === EDITOR_APP_STATUS_VALID;
    },
    icon() {
      switch (this.appStatus) {
        case EDITOR_APP_STATUS_EMPTY:
          return 'check';
        case EDITOR_APP_STATUS_VALID:
          return 'check';
        default:
          return 'warning-solid';
      }
    },
    message() {
      const [reason] = this.ciConfig?.errors || [];

      switch (this.appStatus) {
        case EDITOR_APP_STATUS_EMPTY:
          return this.$options.i18n.empty;
        case EDITOR_APP_STATUS_VALID:
          return this.$options.i18n.valid;
        default:
          // Only display first error as a reason
          return this.ciConfig?.errors.length > 0
            ? sprintf(this.$options.i18n.invalidWithReason, { reason }, false)
            : this.$options.i18n.invalid;
      }
    },
  },
};
</script>

<template>
  <div>
    <template v-if="isLoading">
      <gl-loading-icon size="sm" inline />
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
