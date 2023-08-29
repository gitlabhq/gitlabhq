<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { createAlert } from '~/alert';
import { TYPENAME_COMMIT_STATUS } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import {
  JOB_GRAPHQL_ERRORS,
  JOB_SIDEBAR_COPY,
  forwardDeploymentFailureModalId,
  PASSED_STATUS,
} from '~/jobs/constants';
import GetJob from '../graphql/queries/get_job.query.graphql';
import JobSidebarRetryButton from './job_sidebar_retry_button.vue';

export default {
  name: 'SidebarHeader',
  i18n: {
    ...JOB_SIDEBAR_COPY,
  },
  forwardDeploymentFailureModalId,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    JobSidebarRetryButton,
    TooltipOnTruncate,
  },
  inject: ['projectPath'],
  apollo: {
    job: {
      query: GetJob,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_COMMIT_STATUS, this.jobId),
        };
      },
      update(data) {
        const { name, manualJob } = data?.project?.job || {};
        return {
          name,
          manualJob,
        };
      },
      error() {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobQueryErrorText });
      },
    },
  },
  props: {
    jobId: {
      type: Number,
      required: true,
    },
    restJob: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    return {
      job: {},
    };
  },
  computed: {
    buttonTitle() {
      return this.restJob.status?.text === PASSED_STATUS
        ? this.$options.i18n.runAgainJobButtonLabel
        : this.$options.i18n.retryJobLabel;
    },
    canShowJobRetryButton() {
      return this.restJob.retry_path && !this.$apollo.queries.job.loading;
    },
    isManualJob() {
      return this.job?.manualJob;
    },
    retryButtonCategory() {
      return this.restJob.status && this.restJob.recoverable ? 'primary' : 'secondary';
    },
  },
  methods: {
    ...mapActions(['toggleSidebar']),
  },
};
</script>

<template>
  <div class="gl-py-4">
    <tooltip-on-truncate :title="job.name" truncate-target="child"
      ><h4 class="gl-mt-0 gl-mb-3 gl-text-truncate" data-testid="job-name">{{ job.name }}</h4>
    </tooltip-on-truncate>
    <div class="gl-display-flex gl-gap-3">
      <gl-button
        v-if="restJob.erase_path"
        v-gl-tooltip.bottom
        :title="$options.i18n.eraseLogButtonLabel"
        :aria-label="$options.i18n.eraseLogButtonLabel"
        :href="restJob.erase_path"
        :data-confirm="$options.i18n.eraseLogConfirmText"
        data-testid="job-log-erase-link"
        data-confirm-btn-variant="danger"
        data-method="post"
        icon="remove"
      />
      <gl-button
        v-if="restJob.new_issue_path"
        v-gl-tooltip.bottom
        :href="restJob.new_issue_path"
        :title="$options.i18n.newIssue"
        :aria-label="$options.i18n.newIssue"
        category="secondary"
        variant="confirm"
        data-testid="job-new-issue"
        icon="issue-new"
      />
      <gl-button
        v-if="restJob.terminal_path"
        v-gl-tooltip.bottom
        :href="restJob.terminal_path"
        :title="$options.i18n.debug"
        :aria-label="$options.i18n.debug"
        target="_blank"
        icon="external-link"
        data-testid="terminal-link"
      />
      <job-sidebar-retry-button
        v-if="canShowJobRetryButton"
        v-gl-tooltip.bottom
        :title="buttonTitle"
        :aria-label="buttonTitle"
        :is-manual-job="isManualJob"
        :category="retryButtonCategory"
        :href="restJob.retry_path"
        :modal-id="$options.forwardDeploymentFailureModalId"
        variant="confirm"
        data-qa-selector="retry_button"
        data-testid="retry-button"
        @updateVariablesClicked="$emit('updateVariables')"
      />
      <gl-button
        v-if="restJob.cancel_path"
        v-gl-tooltip.bottom
        :title="$options.i18n.cancelJobButtonLabel"
        :aria-label="$options.i18n.cancelJobButtonLabel"
        :href="restJob.cancel_path"
        variant="danger"
        icon="cancel"
        data-method="post"
        data-testid="cancel-button"
        rel="nofollow"
      />
      <gl-button
        :aria-label="$options.i18n.toggleSidebar"
        category="tertiary"
        class="gl-md-display-none gl-ml-2"
        icon="chevron-double-lg-right"
        @click="toggleSidebar"
      />
    </div>
  </div>
</template>
