<script>
import { GlIntersectionObserver, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import produce from 'immer';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import eventHub from '~/ci/jobs_page/event_hub';
import JobsTable from '~/ci/jobs_page/components/jobs_table.vue';
import { JOBS_TAB_FIELDS } from '~/ci/jobs_page/constants';
import { getQueryHeaders } from '../graph/utils';
import { POLL_INTERVAL } from '../graph/constants';
import getPipelineJobs from './graphql/queries/get_pipeline_jobs.query.graphql';

export default {
  name: 'PipelineJobsApp',
  fields: JOBS_TAB_FIELDS,
  components: {
    GlIntersectionObserver,
    GlLoadingIcon,
    GlSkeletonLoader,
    JobsTable,
  },
  inject: {
    projectPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
    graphqlResourceEtag: {
      default: '',
    },
  },
  apollo: {
    jobs: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineJobs,
      pollInterval: POLL_INTERVAL,
      variables() {
        return {
          ...this.queryVariables,
        };
      },
      update(data) {
        return data.project?.pipeline?.jobs?.nodes || [];
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.jobsPageInfo = data.project?.pipeline?.jobs?.pageInfo || {};
      },
      error(error) {
        createAlert({ message: __('An error occurred while fetching the pipelines jobs.') });
        reportToSentry(this.$options.name, error);
      },
    },
  },
  data() {
    return {
      jobs: [],
      jobsPageInfo: {},
      firstLoad: true,
    };
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.projectPath,
        iid: this.pipelineIid,
      };
    },
    loading() {
      return this.$apollo.queries.jobs.loading;
    },
    showSkeletonLoader() {
      return this.firstLoad && this.loading;
    },
    showLoadingSpinner() {
      return !this.firstLoad && this.loading;
    },
  },
  mounted() {
    eventHub.$on('jobActionPerformed', this.handleJobAction);
  },
  beforeDestroy() {
    eventHub.$off('jobActionPerformed', this.handleJobAction);
  },
  methods: {
    handleJobAction() {
      this.firstLoad = false;

      this.$apollo.queries.jobs.refetch();
    },
    fetchMoreJobs() {
      this.firstLoad = false;

      this.$apollo.queries.jobs.fetchMore({
        variables: {
          ...this.queryVariables,
          after: this.jobsPageInfo.endCursor,
        },
        updateQuery: (previousResult, { fetchMoreResult }) => {
          const results = produce(fetchMoreResult, (draftData) => {
            draftData.project.pipeline.jobs.nodes = [
              ...previousResult.project.pipeline.jobs.nodes,
              ...draftData.project.pipeline.jobs.nodes,
            ];
          });
          return results;
        },
      });
    },
  },
};
</script>

<template>
  <div>
    <div v-if="showSkeletonLoader" class="gl-mt-5">
      <gl-skeleton-loader :width="1248" :height="73">
        <circle cx="748.031" cy="37.7193" r="15.0307" />
        <circle cx="787.241" cy="37.7193" r="15.0307" />
        <circle cx="827.759" cy="37.7193" r="15.0307" />
        <circle cx="866.969" cy="37.7193" r="15.0307" />
        <circle cx="380" cy="37" r="18" />
        <rect x="432" y="19" width="126.587" height="15" />
        <rect x="432" y="41" width="247" height="15" />
        <rect x="158" y="19" width="86.1" height="15" />
        <rect x="158" y="41" width="168" height="15" />
        <rect x="22" y="19" width="96" height="36" />
        <rect x="924" y="30" width="96" height="15" />
        <rect x="1057" y="20" width="166" height="35" />
      </gl-skeleton-loader>
    </div>

    <jobs-table v-else :jobs="jobs" :table-fields="$options.fields" data-testid="jobs-tab-table" />

    <gl-intersection-observer v-if="jobsPageInfo.hasNextPage" @appear="fetchMoreJobs">
      <gl-loading-icon v-if="showLoadingSpinner" size="lg" />
    </gl-intersection-observer>
  </div>
</template>
