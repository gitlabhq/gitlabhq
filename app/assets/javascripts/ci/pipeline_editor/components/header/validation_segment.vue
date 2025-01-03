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
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    hasLink() {
      return this.appStatus !== EDITOR_APP_STATUS_EMPTY;
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
  <div>
    <div v-if="isLoading" class="gl-mx-2 gl-flex gl-items-center">
      <gl-loading-icon class="gl-mr-4" />
      {{ $options.i18n.loading }}
    </div>
    <span v-else data-testid="validation-segment">
      <span class="gl-flex gl-max-w-full gl-items-center gl-gap-4">
        <gl-icon :name="icon" class="gl-ml-1" />
        <gl-sprintf :message="message">
          <template v-if="hasLink" #link="{ content }">
            <gl-link :href="helpPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </span>
  </div>
</template>
