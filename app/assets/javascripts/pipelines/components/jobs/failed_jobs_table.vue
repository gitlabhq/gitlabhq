<script>
import { GlButton, GlLink, GlTableLite } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { redirectTo } from '~/lib/utils/url_utility';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import RetryFailedJobMutation from '../../graphql/mutations/retry_failed_job.mutation.graphql';
import { DEFAULT_FIELDS } from '../../constants';

export default {
  fields: DEFAULT_FIELDS,
  retry: __('Retry'),
  components: {
    CiBadgeLink,
    GlButton,
    GlLink,
    GlTableLite,
  },
  directives: {
    SafeHtml,
  },
  props: {
    failedJobs: {
      type: Array,
      required: true,
    },
  },
  methods: {
    async retryJob(id) {
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
          redirectTo(job.detailedStatus.detailsPath);
        }
      } catch {
        this.showErrorMessage();
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
      <div
        class="gl-display-flex gl-align-items-center gl-lg-justify-content-start gl-justify-content-end"
      >
        <ci-badge-link :status="item.detailedStatus" :show-text="false" class="gl-mr-3" />
        <div class="gl-text-truncate">
          <gl-link
            :href="item.detailedStatus.detailsPath"
            class="gl-font-weight-bold gl-text-gray-900!"
          >
            {{ item.name }}
          </gl-link>
        </div>
      </div>
    </template>

    <template #cell(stage)="{ item }">
      <div class="gl-text-truncate">
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
        class="gl-w-full gl-text-left gl-border-none"
        data-testid="job-log"
      >
        <code v-safe-html="failureSummary(item.trace)" class="gl-reset-bg gl-p-0" data-testid="job-trace-summary">
        </code>
      </pre>
    </template>
  </gl-table-lite>
</template>
