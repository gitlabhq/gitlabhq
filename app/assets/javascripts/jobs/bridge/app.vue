<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, sprintf } from '~/locale';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import getPipelineQuery from './graphql/queries/pipeline.query.graphql';
import BridgeEmptyState from './components/empty_state.vue';
import BridgeSidebar from './components/sidebar.vue';
import { SIDEBAR_COLLAPSE_BREAKPOINTS } from './components/constants';

export default {
  name: 'BridgePageApp',
  components: {
    BridgeEmptyState,
    BridgeSidebar,
    CiHeader,
    GlLoadingIcon,
  },
  inject: ['buildId', 'projectFullPath', 'pipelineIid'],
  apollo: {
    pipeline: {
      query: getPipelineQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        if (!data?.project?.pipeline) {
          return null;
        }

        const { pipeline } = data.project;
        const stages = pipeline?.stages.edges.map((edge) => edge.node) || [];
        const jobs = stages.map((stage) => stage.jobs.nodes).flat();

        return {
          ...pipeline,
          commit: {
            ...pipeline.commit,
            commit_path: pipeline.commit.webPath,
            short_id: pipeline.commit.shortId,
          },
          id: getIdFromGraphQLId(pipeline.id),
          jobs,
          stages,
        };
      },
    },
  },
  data() {
    return {
      isSidebarExpanded: true,
      pipeline: {},
    };
  },
  computed: {
    bridgeJob() {
      return (
        this.pipeline.jobs?.filter(
          (job) => getIdFromGraphQLId(job.id) === Number(this.buildId),
        )[0] || {}
      );
    },
    bridgeName() {
      return sprintf(__('Job %{jobName}'), { jobName: this.bridgeJob.name });
    },
    isPipelineLoading() {
      return this.$apollo.queries.pipeline.loading;
    },
  },
  created() {
    window.addEventListener('resize', this.onResize);
  },
  mounted() {
    this.onResize();
  },
  methods: {
    toggleSidebar() {
      this.isSidebarExpanded = !this.isSidebarExpanded;
    },
    onResize() {
      const breakpoint = bp.getBreakpointSize();
      if (SIDEBAR_COLLAPSE_BREAKPOINTS.includes(breakpoint)) {
        this.isSidebarExpanded = false;
      } else if (!this.isSidebarExpanded) {
        this.isSidebarExpanded = true;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isPipelineLoading" size="lg" class="gl-mt-4" />
    <div v-else>
      <ci-header
        class="gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
        :status="bridgeJob.detailedStatus"
        :time="bridgeJob.createdAt"
        :user="pipeline.user"
        :has-sidebar-button="true"
        :item-name="bridgeName"
        @clickedSidebarButton="toggleSidebar"
      />
      <bridge-empty-state :downstream-pipeline-path="bridgeJob.downstreamPipeline.path" />
      <bridge-sidebar
        v-if="isSidebarExpanded"
        :bridge-job="bridgeJob"
        :commit="pipeline.commit"
        :is-sidebar-expanded="isSidebarExpanded"
        @toggleSidebar="toggleSidebar"
      />
    </div>
  </div>
</template>
