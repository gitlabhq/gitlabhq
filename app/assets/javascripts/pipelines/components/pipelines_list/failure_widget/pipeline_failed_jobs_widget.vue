<script>
import { GlButton, GlCollapse, GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { etagQueryHeaders } from '~/graphql_shared/utils';
import getPipelineFailedJobsCount from '../../../graphql/queries/get_pipeline_failed_jobs_count.query.graphql';
import { graphqlEtagPipelinePath } from './utils';
import FailedJobsList from './failed_jobs_list.vue';

const POLL_INTERVAL = 10000;

export default {
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
    FailedJobsList,
  },
  inject: ['fullPath', 'graphqlPath'],
  props: {
    isPipelineActive: {
      required: true,
      type: Boolean,
    },
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
      failedJobsCount: 0,
      isActive: false,
      isExpanded: false,
    };
  },
  apollo: {
    failedJobsCount: {
      context() {
        return etagQueryHeaders('verify/ci/merge-request/pipelines', this.graphqlResourceEtag);
      },
      query: getPipelineFailedJobsCount,
      variables() {
        return {
          fullPath: this.fullPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update(data) {
        return data?.project?.pipeline?.jobs?.count || 0;
      },
      result({ data }) {
        this.isActive = data?.project?.pipeline?.active || false;
      },
    },
  },
  computed: {
    bodyClasses() {
      return this.isExpanded ? '' : 'gl-display-none';
    },
    failedJobsCountText() {
      return sprintf(this.$options.i18n.showFailedJobs, { count: this.failedJobsCount });
    },
    graphqlResourceEtag() {
      return graphqlEtagPipelinePath(this.graphqlPath, this.pipelineIid);
    },
    hasFailedJobs() {
      return this.failedJobsCount > 0;
    },
    iconName() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
    },
  },
  watch: {
    isPipelineActive(flag) {
      // Turn polling on and off based on REST actions
      // By refetching jobs, we will get the graphql `active`
      // field to update properly and cascade the polling changes
      this.$apollo.queries.failedJobsCount.refetch();
      this.handlePolling(flag);
    },
    isActive(flag) {
      this.handlePolling(flag);
    },
    isExpanded(flag) {
      // When the user toggles the expand state, we check if the pipeline is
      // active, which which case we restart polling for jobs count.
      if (!flag && (this.isActive || this.isPipelineActive)) {
        this.$apollo.queries.failedJobsCount.startPolling(POLL_INTERVAL);
      } else {
        this.$apollo.queries.failedJobsCount.stopPolling();
      }
    },
  },
  methods: {
    handlePolling(isActive) {
      // If the pipeline status has changed and the widget is not expanded,
      // We start polling.
      if (!this.isExpanded && isActive) {
        this.$apollo.queries.failedJobsCount.startPolling(POLL_INTERVAL);
      } else {
        this.$apollo.queries.failedJobsCount.stopPolling();
      }
    },
    setFailedJobsCount(count) {
      this.failedJobsCount = count;
    },
    toggleWidget() {
      this.isExpanded = !this.isExpanded;
    },
  },
  i18n: {
    additionalInfoPopover: s__(
      'Pipelines|You will see a maximum of 100 jobs in this list. To view all failed jobs, %{linkStart}go to the details page%{linkEnd} of this pipeline.',
    ),
    additionalInfoTitle: __('Limitation on this view'),
    showFailedJobs: __('Show failed jobs (%{count})'),
  },
};
</script>
<template>
  <div class="gl-border-none!">
    <gl-button variant="link" @click="toggleWidget">
      <gl-icon :name="iconName" />
      {{ failedJobsCountText }}
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
    <gl-collapse
      v-model="isExpanded"
      class="gl-bg-gray-10 gl-border-1 gl-border-t gl-border-color-gray-100 gl-mt-4 gl-pt-3"
    >
      <failed-jobs-list
        v-if="isExpanded"
        :graphql-resource-etag="graphqlResourceEtag"
        :is-pipeline-active="isPipelineActive"
        :pipeline-iid="pipelineIid"
        @failed-jobs-count="setFailedJobsCount"
      />
    </gl-collapse>
  </div>
</template>
