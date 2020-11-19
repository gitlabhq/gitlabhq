<script>
import { mapState } from 'vuex';
import DetailRow from './sidebar_detail_row.vue';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';

export default {
  name: 'JobSidebarDetailsContainer',
  components: {
    DetailRow,
  },
  mixins: [timeagoMixin],
  props: {
    runnerHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['job']),
    coverage() {
      return `${this.job.coverage}%`;
    },
    duration() {
      return timeIntervalInWords(this.job.duration);
    },
    erasedAt() {
      return this.timeFormatted(this.job.erased_at);
    },
    finishedAt() {
      return this.timeFormatted(this.job.finished_at);
    },
    hasTags() {
      return this.job?.tags?.length;
    },
    hasTimeout() {
      return this.job?.metadata?.timeout_human_readable ?? false;
    },
    hasAnyDetail() {
      return Boolean(
        this.job.duration ||
          this.job.finished_at ||
          this.job.erased_at ||
          this.job.queued ||
          this.job.runner ||
          this.job.coverage,
      );
    },
    queued() {
      return timeIntervalInWords(this.job.queued);
    },
    runnerId() {
      return `${this.job.runner.description} (#${this.job.runner.id})`;
    },
    shouldRenderBlock() {
      return Boolean(this.hasAnyDetail || this.hasTimeout || this.hasTags);
    },
    timeout() {
      return `${this.job?.metadata?.timeout_human_readable}${this.timeoutSource}`;
    },
    timeoutSource() {
      if (!this.job?.metadata?.timeout_source) {
        return '';
      }

      return sprintf(__(` (from %{timeoutSource})`), {
        timeoutSource: this.job.metadata.timeout_source,
      });
    },
  },
};
</script>

<template>
  <div v-if="shouldRenderBlock" class="block">
    <detail-row v-if="job.duration" :value="duration" title="Duration" />
    <detail-row
      v-if="job.finished_at"
      :value="finishedAt"
      data-testid="job-finished"
      title="Finished"
    />
    <detail-row v-if="job.erased_at" :value="erasedAt" title="Erased" />
    <detail-row v-if="job.queued" :value="queued" title="Queued" />
    <detail-row
      v-if="hasTimeout"
      :help-url="runnerHelpUrl"
      :value="timeout"
      data-testid="job-timeout"
      title="Timeout"
    />
    <detail-row v-if="job.runner" :value="runnerId" title="Runner" />
    <detail-row v-if="job.coverage" :value="coverage" title="Coverage" />

    <p v-if="hasTags" class="build-detail-row" data-testid="job-tags">
      <span class="font-weight-bold">{{ __('Tags:') }}</span>
      <span v-for="(tag, i) in job.tags" :key="i" class="badge badge-primary mr-1">{{ tag }}</span>
    </p>
  </div>
</template>
