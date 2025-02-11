<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlLink,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { s__, __, sprintf } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagPipelinePath } from '~/ci/pipeline_details/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import { sortJobsByStatus } from './utils/data_utils';
import getDownstreamPipelineJobsQuery from './graphql/queries/get_downstream_pipeline_jobs.query.graphql';

/**
 * Renders a downstream pipeline dropdown for the pipeline mini graph.
 */
export default {
  name: 'DownstreamPipelineDropdown',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    GlButton,
    GlDisclosureDropdown,
    GlLink,
    GlLoadingIcon,
    JobDropdownItem,
    TooltipOnTruncate,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  emits: ['jobActionExecuted'],
  data() {
    return {
      isDropdownOpen: false,
      pipelineJobs: [],
    };
  },
  apollo: {
    pipelineJobs: {
      context() {
        return getQueryHeaders(this.graphqlEtag);
      },
      query: getDownstreamPipelineJobsQuery,
      variables() {
        return {
          iid: this.pipeline.iid,
          fullPath: this.projectPath,
        };
      },
      skip() {
        return !this.isDropdownOpen || !this.projectPath;
      },
      pollInterval: PIPELINE_POLL_INTERVAL_DEFAULT,
      update({ project }) {
        const jobs = project?.pipeline?.jobs?.nodes || [];
        return sortJobsByStatus(jobs);
      },
      error(error) {
        createAlert({
          message: s__('Pipelines|There was a problem fetching the downstream pipeline jobs.'),
        });

        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    dropdownAriaLabel() {
      return sprintf(__('View Pipeline: %{title}'), { title: this.pipelineName });
    },
    dropdownHeaderText() {
      return `${__('Pipeline')}: ${this.pipelineName}`;
    },
    dropdownTooltipTitle() {
      const status = this.pipeline?.detailedStatus?.label || __('unknown');

      return `${this.pipelineName} - ${status}`;
    },
    graphqlEtag() {
      return graphqlEtagPipelinePath('/api/graphql', this.pipelineId);
    },
    isLoading() {
      return this.$apollo.queries.pipelineJobs.loading;
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline.id).toString();
    },
    pipelineName() {
      return this.pipeline?.name || this.pipeline?.project?.name || __('Downstream pipeline');
    },
    projectPath() {
      return this.pipeline?.project?.fullPath || '';
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipelineJobs);
  },
  methods: {
    onHideDropdown() {
      this.isDropdownOpen = false;
      this.$apollo.queries.pipelineJobs.stopPolling();
    },
    onShowDropdown() {
      this.isDropdownOpen = true;
      this.$apollo.queries.pipelineJobs.startPolling(PIPELINE_POLL_INTERVAL_DEFAULT);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    data-testid="pipeline-mini-graph-dropdown"
    :aria-label="dropdownAriaLabel"
    fluid-width
    @hidden="onHideDropdown"
    @shown="onShowDropdown"
  >
    <template #toggle>
      <gl-button
        v-gl-tooltip.hover="dropdownTooltipTitle"
        data-testid="pipeline-mini-graph-dropdown-toggle"
        :title="dropdownTooltipTitle"
        class="!gl-rounded-full"
        variant="link"
      >
        <ci-icon :status="pipeline.detailedStatus" :show-tooltip="false" :use-link="false" />
      </gl-button>
    </template>

    <template #header>
      <div
        class="gl-flex gl-min-h-8 gl-flex-col gl-gap-2 gl-border-b-1 gl-border-b-dropdown !gl-p-4 gl-text-sm gl-leading-1 gl-border-b-solid"
      >
        <span class="gl-font-bold">{{ dropdownHeaderText }}</span>
        <p class="!gl-m-0">
          <tooltip-on-truncate :title="pipelineId" class="gl-grow gl-truncate gl-text-default">
            <gl-link :href="pipeline.path">#{{ pipelineId }}</gl-link>
          </tooltip-on-truncate>
        </p>
      </div>
    </template>

    <div v-if="isLoading" class="gl-flex gl-gap-3 gl-px-4 gl-py-3">
      <gl-loading-icon size="sm" />
      <span class="gl-leading-normal">{{ __('Loading...') }}</span>
    </div>
    <ul
      v-else
      class="gl-m-0 gl-w-34 gl-overflow-y-auto gl-p-0"
      data-testid="downstream-jobs-list"
      @click.stop
    >
      <job-dropdown-item
        v-for="job in pipelineJobs"
        :key="job.id"
        :job="job"
        @jobActionExecuted="$emit('jobActionExecuted')"
      />
    </ul>
  </gl-disclosure-dropdown>
</template>
