<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapActions } from 'vuex';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { JOB_SIDEBAR_COPY, forwardDeploymentFailureModalId } from '~/jobs/constants';
import JobSidebarRetryButton from './job_sidebar_retry_button.vue';

export default {
  name: 'LegacySidebarHeader',
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
  props: {
    job: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    erasePath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    retryButtonCategory() {
      return this.job.status && this.job.recoverable ? 'primary' : 'secondary';
    },
    buttonTitle() {
      return this.job.status && this.job.status.text === 'passed'
        ? this.$options.i18n.runAgainJobButtonLabel
        : this.$options.i18n.retryJobButtonLabel;
    },
  },
  methods: {
    ...mapActions(['toggleSidebar']),
  },
};
</script>

<template>
  <div class="gl-py-5 gl-display-flex gl-align-items-center">
    <tooltip-on-truncate :title="job.name" truncate-target="child"
      ><h4 class="gl-my-0 gl-mr-3 gl-text-truncate">
        {{ job.name }}
      </h4>
    </tooltip-on-truncate>
    <div class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right">
      <gl-button
        v-if="erasePath"
        v-gl-tooltip.left
        :title="$options.i18n.eraseLogButtonLabel"
        :aria-label="$options.i18n.eraseLogButtonLabel"
        :href="erasePath"
        :data-confirm="$options.i18n.eraseLogConfirmText"
        class="gl-mr-2"
        data-testid="job-log-erase-link"
        data-confirm-btn-variant="danger"
        data-method="post"
        icon="remove"
      />
      <job-sidebar-retry-button
        v-if="job.retry_path"
        v-gl-tooltip.left
        :title="buttonTitle"
        :aria-label="buttonTitle"
        :category="retryButtonCategory"
        :href="job.retry_path"
        :modal-id="$options.forwardDeploymentFailureModalId"
        variant="confirm"
        data-qa-selector="retry_button"
        data-testid="retry-button"
      />
      <gl-button
        v-if="job.cancel_path"
        v-gl-tooltip.left
        :title="$options.i18n.cancelJobButtonLabel"
        :aria-label="$options.i18n.cancelJobButtonLabel"
        :href="job.cancel_path"
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
