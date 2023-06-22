<script>
import {
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPopover,
  GlSprintf,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import getPipelineFailedJobs from '../../../graphql/queries/get_pipeline_failed_jobs.query.graphql';
import WidgetFailedJobRow from './widget_failed_job_row.vue';
import { sortJobsByStatus } from './utils';

const JOB_ACTION_HEADER = __('Actions');
const JOB_ID_HEADER = __('Job ID');
const JOB_NAME_HEADER = __('Job name');
const STAGE_HEADER = __('Stage');

export default {
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
    WidgetFailedJobRow,
  },
  inject: ['fullPath'],
  props: {
    pipelineIid: {
      required: true,
      type: Number,
    },
    pipelinePath: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      failedJobs: [],
      isExpanded: false,
      isLoadingMore: false,
    };
  },
  apollo: {
    failedJobs: {
      query: getPipelineFailedJobs,
      skip() {
        return !this.isExpanded;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update(data) {
        const jobs = data?.project?.pipeline?.jobs?.nodes || [];
        return sortJobsByStatus(jobs);
      },
      error(e) {
        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      },
    },
  },
  computed: {
    bodyClasses() {
      return this.isExpanded ? '' : 'gl-display-none';
    },
    failedJobsCount() {
      return this.failedJobs.length;
    },
    iconName() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
    isInitialLoading() {
      return this.isLoading && !this.isLoadingMore;
    },
    isLoading() {
      return this.$apollo.queries.failedJobs.loading;
    },
  },
  methods: {
    async refetchJobs(jobName) {
      this.isLoadingMore = true;

      await this.$apollo.queries.failedJobs.refetch();

      this.isLoadingMore = false;
      this.$toast.show(sprintf(this.$options.i18n.retriedJobsSuccess, { jobName }));
    },
    toggleWidget() {
      this.isExpanded = !this.isExpanded;
    },
  },
  columns: [
    { text: JOB_NAME_HEADER, class: 'col-6' },
    { text: STAGE_HEADER, class: 'col-2' },
    { text: JOB_ID_HEADER, class: 'col-2' },
    { text: JOB_ACTION_HEADER, class: 'col-2' },
  ],
  i18n: {
    additionalInfoPopover: s__(
      'Pipelines|You will see a maximum of 100 jobs in this list. To view all failed jobs, %{linkStart}go to the details page%{linkEnd} of this pipeline.',
    ),
    additionalInfoTitle: __('Limitation on this view'),
    fetchError: __('There was a problem fetching failed jobs'),
    showFailedJobs: __('Show failed jobs'),
    retriedJobsSuccess: __('%{jobName} job is being retried'),
  },
};
</script>
<template>
  <div class="gl-border-none!">
    <gl-button variant="link" @click="toggleWidget">
      <gl-icon :name="iconName" />
      {{ $options.i18n.showFailedJobs }}
      <gl-icon id="target" name="information-o" />
      <gl-popover target="target" placement="top">
        <template #title> {{ $options.i18n.additionalInfoTitle }} </template>
        <slot>
          <gl-sprintf :message="$options.i18n.additionalInfoPopover">
            <template #link="{ content }">
              <gl-link class="gl-font-sm" :href="pipelinePath"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </slot>
      </gl-popover>
    </gl-button>
    <gl-loading-icon v-if="isInitialLoading" />
    <gl-collapse
      v-else
      v-model="isExpanded"
      class="gl-bg-gray-10 gl-border-1 gl-border-t gl-border-color-gray-100 gl-mt-4 gl-pt-3"
    >
      <div class="container-fluid gl-grid-tpl-rows-auto">
        <div class="row gl-mb-6 gl-text-gray-900">
          <div
            v-for="col in $options.columns"
            :key="col.text"
            class="gl-font-weight-bold gl-text-left"
            :class="col.class"
            data-testid="header"
          >
            {{ col.text }}
          </div>
        </div>
      </div>
      <widget-failed-job-row
        v-for="job in failedJobs"
        :key="job.id"
        :job="job"
        @job-retried="refetchJobs"
      />
    </gl-collapse>
  </div>
</template>
