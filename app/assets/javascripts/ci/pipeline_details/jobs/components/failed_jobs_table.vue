<script>
import { GlButton, GlLink, GlTableLite } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { reportToSentry } from '~/ci/utils';
import Tracking from '~/tracking';
import { visitUrl } from '~/lib/utils/url_utility';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import RetryFailedJobMutation from '../graphql/mutations/retry_failed_job.mutation.graphql';
import { DEFAULT_FIELDS } from '../../constants';

export default {
  name: 'PipelineFailedJobsTable',
  fields: DEFAULT_FIELDS,
  retry: __('Retry'),
  components: {
    CiIcon,
    GlButton,
    GlLink,
    GlTableLite,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  props: {
    failedJobs: {
      type: Array,
      required: true,
    },
  },
  methods: {
    async retryJob(id) {
      this.track('click_retry', { label: TRACKING_CATEGORIES.failed });

      try {
        const {
          data: {
            jobRetry: { errors, job },
          },
        } = await this.$apollo.mutate({
          mutation: RetryFailedJobMutation,
          variables: { id },
        });
        if (errors.length > 0) {
          this.showErrorMessage();
        } else {
          visitUrl(job.detailedStatus.detailsPath);
        }
      } catch (error) {
        this.showErrorMessage();
        reportToSentry(this.$options.name, error);
      }
    },
    canRetryJob(job) {
      return job.retryable && job.userPermissions.updateBuild;
    },
    showErrorMessage() {
      createAlert({ message: s__('Job|There was a problem retrying the failed job.') });
    },
    failureSummary(trace) {
      return trace ? trace.htmlSummary : s__('Job|No job log');
    },
  },
};
</script>

<template>
  <gl-table-lite
    :items="failedJobs"
    :fields="$options.fields"
    stacked="lg"
    fixed
    data-testId="tab-failures"
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(name)="{ item }">
      <div class="gl-flex gl-items-center gl-justify-end lg:gl-justify-start">
        <ci-icon :status="item.detailedStatus" class="gl-mr-3" />
        <div class="gl-truncate">
          <gl-link :href="item.detailedStatus.detailsPath" class="gl-font-bold !gl-text-default">
            {{ item.name }}
          </gl-link>
        </div>
      </div>
    </template>

    <template #cell(stage)="{ item }">
      <div class="gl-truncate">
        <span>{{ item.stage.name }}</span>
      </div>
    </template>

    <template #cell(failureMessage)="{ item }">
      <span data-testid="job-failure-message">{{ item.failureMessage }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <gl-button
        v-if="canRetryJob(item)"
        icon="retry"
        :title="$options.retry"
        :aria-label="$options.retry"
        @click="retryJob(item.id)"
      />
    </template>

    <template #row-details="{ item }">
      <pre
        v-if="item.userPermissions.readBuild"
        class="gl-w-full gl-border-none gl-text-left"
        data-testid="job-log"
      >
        <code v-safe-html="failureSummary(item.trace)" class="gl-bg-inherit gl-p-0" data-testid="job-trace-summary">
        </code>
      </pre>
    </template>
  </gl-table-lite>
</template>
