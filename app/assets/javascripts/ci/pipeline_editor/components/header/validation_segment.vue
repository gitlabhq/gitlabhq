<script>
import { GlIcon, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import getAppStatus from '~/ci/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import {
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_LINT_UNAVAILABLE,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
} from '../../constants';

export const i18n = {
  empty: s__(
    "Pipelines|We'll continuously validate your pipeline configuration. The validation results will appear here.",
  ),
  loading: s__('Pipelines|Validating GitLab CI configuration…'),
  invalid: s__(
    'Pipelines|This GitLab CI configuration is invalid. %{linkStart}Learn more%{linkEnd}',
  ),
  invalidWithReason: s__(
    'Pipelines|This GitLab CI configuration is invalid: %{reason}. %{linkStart}Learn more%{linkEnd}',
  ),
  unavailableValidation: s__(
    'Pipelines|Unable to validate CI/CD configuration. See the %{linkStart}GitLab CI/CD troubleshooting guide%{linkEnd} for more details.',
  ),
  valid: s__('Pipelines|Pipeline syntax is correct. %{linkStart}Learn more%{linkEnd}'),
};

export default {
  i18n,
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  inject: {
    ciTroubleshootingPath: {
      default: '',
    },
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
  data() {
    return {
      appStatus: EDITOR_APP_STATUS_LOADING,
    };
  },
  apollo: {
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
  },
  computed: {
    APP_STATUS_CONFIG() {
      return {
        [EDITOR_APP_STATUS_EMPTY]: {
          icon: 'check',
          message: this.$options.i18n.empty,
        },
        [EDITOR_APP_STATUS_LINT_UNAVAILABLE]: {
          icon: 'time-out',
          link: this.ciTroubleshootingPath,
          message: this.$options.i18n.unavailableValidation,
        },
        [EDITOR_APP_STATUS_VALID]: {
          icon: 'check',
          message: this.$options.i18n.valid,
        },
      };
    },
    currentAppStatusConfig() {
      return this.APP_STATUS_CONFIG[this.appStatus] || {};
    },
    helpPath() {
      return this.currentAppStatusConfig.link || this.ymlHelpPagePath;
    },
    isLoading() {
      return this.appStatus === EDITOR_APP_STATUS_LOADING;
    },
    icon() {
      return this.currentAppStatusConfig.icon || 'warning-solid';
    },
    message() {
      const [reason] = this.ciConfig?.errors || [];

      return (
        this.currentAppStatusConfig.message ||
        // Only display first error as a reason
        (reason
          ? sprintf(this.$options.i18n.invalidWithReason, { reason }, false)
          : this.$options.i18n.invalid)
      );
    },
  },
};
</script>

<template>
  <div v-if="isLoading" class="gl-flex gl-items-center gl-gap-3">
    <gl-loading-icon class="gl-mx-2" />
    {{ $options.i18n.loading }}
  </div>
  <div v-else class="gl-flex gl-gap-3" data-testid="validation-segment">
    <gl-icon :name="icon" class="gl-mx-2 gl-mt-1 gl-shrink-0" />
    <span data-testid="validation-message">
      <gl-sprintf :message="message">
        <template #link="{ content }">
          <gl-link :href="helpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
