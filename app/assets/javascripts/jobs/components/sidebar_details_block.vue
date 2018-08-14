<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';
import DetailRow from './sidebar_detail_row.vue';

export default {
  name: 'SidebarDetailsBlock',
  components: {
    DetailRow,
    LoadingIcon,
    Icon,
  },
  mixins: [timeagoMixin],
  props: {
    job: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    runnerHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
    terminalPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldRenderContent() {
      return !this.isLoading && Object.keys(this.job).length > 0;
    },
    coverage() {
      return `${this.job.coverage}%`;
    },
    duration() {
      return timeIntervalInWords(this.job.duration);
    },
    queued() {
      return timeIntervalInWords(this.job.queued);
    },
    runnerId() {
      return `${this.job.runner.description} (#${this.job.runner.id})`;
    },
    retryButtonClass() {
      let className =
        'js-retry-button float-right btn btn-retry d-none d-md-block d-lg-block d-xl-block';
      className +=
        this.job.status && this.job.recoverable ? ' btn-primary' : ' btn-inverted-secondary';
      return className;
    },
    hasTimeout() {
      return this.job.metadata != null && this.job.metadata.timeout_human_readable !== null;
    },
    timeout() {
      if (this.job.metadata == null) {
        return '';
      }

      let t = this.job.metadata.timeout_human_readable;
      if (this.job.metadata.timeout_source !== '') {
        t += ` (from ${this.job.metadata.timeout_source})`;
      }

      return t;
    },
    renderBlock() {
      return (
        this.job.merge_request ||
        this.job.duration ||
        this.job.finished_data ||
        this.job.erased_at ||
        this.job.queued ||
        this.job.runner ||
        this.job.coverage ||
        this.job.tags.length ||
        this.job.cancel_path
      );
    },
  },
};
</script>
<template>
  <div>
    <div class="block">
      <strong class="inline prepend-top-8">
        {{ job.name }}
      </strong>
      <a
        v-if="job.retry_path"
        :class="retryButtonClass"
        :href="job.retry_path"
        data-method="post"
        rel="nofollow"
      >
        {{ __('Retry') }}
      </a>
      <a
        v-if="terminalPath"
        :href="terminalPath"
        class="js-terminal-link pull-right btn btn-primary
  btn-inverted visible-md-block visible-lg-block"
        target="_blank"
      >
        {{ __('Debug') }}
        <icon name="external-link" />
      </a>
      <button
        :aria-label="__('Toggle Sidebar')"
        type="button"
        class="btn btn-blank gutter-toggle float-right d-block d-md-none js-sidebar-build-toggle"
      >
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-angle-double-right"
        ></i>
      </button>
    </div>
    <template v-if="shouldRenderContent">
      <div
        v-if="job.retry_path || job.new_issue_path"
        class="block retry-link"
      >
        <a
          v-if="job.new_issue_path"
          :href="job.new_issue_path"
          class="js-new-issue btn btn-new btn-inverted"
        >
          {{ __('New issue') }}
        </a>
        <a
          v-if="job.retry_path"
          :href="job.retry_path"
          class="js-retry-job btn btn-inverted-secondary"
          data-method="post"
          rel="nofollow"
        >
          {{ __('Retry') }}
        </a>
      </div>
      <div :class="{block : renderBlock }">
        <p
          v-if="job.merge_request"
          class="build-detail-row js-job-mr"
        >
          <span class="build-light-text">
            {{ __('Merge Request:') }}
          </span>
          <a :href="job.merge_request.path">
            !{{ job.merge_request.iid }}
          </a>
        </p>

        <detail-row
          v-if="job.duration"
          :value="duration"
          class="js-job-duration"
          title="Duration"
        />
        <detail-row
          v-if="job.finished_at"
          :value="timeFormated(job.finished_at)"
          class="js-job-finished"
          title="Finished"
        />
        <detail-row
          v-if="job.erased_at"
          :value="timeFormated(job.erased_at)"
          class="js-job-erased"
          title="Erased"
        />
        <detail-row
          v-if="job.queued"
          :value="queued"
          class="js-job-queued"
          title="Queued"
        />
        <detail-row
          v-if="hasTimeout"
          :help-url="runnerHelpUrl"
          :value="timeout"
          class="js-job-timeout"
          title="Timeout"
        />
        <detail-row
          v-if="job.runner"
          :value="runnerId"
          class="js-job-runner"
          title="Runner"
        />
        <detail-row
          v-if="job.coverage"
          :value="coverage"
          class="js-job-coverage"
          title="Coverage"
        />
        <p
          v-if="job.tags.length"
          class="build-detail-row js-job-tags"
        >
          <span class="build-light-text">
            {{ __('Tags:') }}
          </span>
          <span
            v-for="(tag, i) in job.tags"
            :key="i"
            class="label label-primary">
            {{ tag }}
          </span>
        </p>

        <div
          v-if="job.cancel_path"
          class="btn-group prepend-top-5"
          role="group">
          <a
            :href="job.cancel_path"
            class="js-cancel-job btn btn-sm btn-default"
            data-method="post"
            rel="nofollow"
          >
            {{ __('Cancel') }}
          </a>
        </div>
      </div>
    </template>
    <loading-icon
      v-if="isLoading"
      class="prepend-top-10"
      size="2"
    />
  </div>
</template>
