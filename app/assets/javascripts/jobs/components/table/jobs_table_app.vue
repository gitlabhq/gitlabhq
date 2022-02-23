<script>
import { GlAlert, GlSkeletonLoader, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from './event_hub';
import GetJobs from './graphql/queries/get_jobs.query.graphql';
import JobsTable from './jobs_table.vue';
import JobsTableEmptyState from './jobs_table_empty_state.vue';
import JobsTableTabs from './jobs_table_tabs.vue';

export default {
  i18n: {
    errorMsg: __('There was an error fetching the jobs for your project.'),
    loadingAriaLabel: __('Loading'),
  },
  components: {
    GlAlert,
    GlSkeletonLoader,
    JobsTable,
    JobsTableEmptyState,
    JobsTableTabs,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  apollo: {
    jobs: {
      query: GetJobs,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        const { jobs: { nodes: list = [], pageInfo = {} } = {} } = data.project || {};
        return {
          list,
          pageInfo,
        };
      },
      error() {
        this.hasError = true;
      },
    },
  },
  data() {
    return {
      jobs: {
        list: [],
      },
      hasError: false,
      isAlertDismissed: false,
      scope: null,
      firstLoad: true,
    };
  },
  computed: {
    shouldShowAlert() {
      return this.hasError && !this.isAlertDismissed;
    },
    showEmptyState() {
      return this.jobs.list.length === 0 && !this.scope;
    },
    hasNextPage() {
      return this.jobs?.pageInfo?.hasNextPage;
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
      this.$apollo.queries.jobs.refetch({ statuses: this.scope });
    },
    fetchJobsByStatus(scope) {
      this.firstLoad = true;

      this.scope = scope;

      this.$apollo.queries.jobs.refetch({ statuses: scope });
    },
    fetchMoreJobs() {
      this.firstLoad = false;

      if (!this.$apollo.queries.jobs.loading) {
        this.$apollo.queries.jobs.fetchMore({
          variables: {
            fullPath: this.fullPath,
            after: this.jobs?.pageInfo?.endCursor,
          },
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mt-2"
      variant="danger"
      dismissible
      @dismiss="isAlertDismissed = true"
    >
      {{ $options.i18n.errorMsg }}
    </gl-alert>

    <jobs-table-tabs @fetchJobsByStatus="fetchJobsByStatus" />

    <div v-if="$apollo.loading && firstLoad" class="gl-mt-5">
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

    <jobs-table-empty-state v-else-if="showEmptyState" />

    <jobs-table v-else :jobs="jobs.list" />

    <gl-intersection-observer v-if="hasNextPage" @appear="fetchMoreJobs">
      <gl-loading-icon
        v-if="$apollo.loading"
        size="md"
        :aria-label="$options.i18n.loadingAriaLabel"
      />
    </gl-intersection-observer>
  </div>
</template>
