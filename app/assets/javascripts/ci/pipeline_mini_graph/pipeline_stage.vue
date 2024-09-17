<script>
import { GlButton, GlDisclosureDropdown, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { PIPELINE_MINI_GRAPH_POLL_INTERVAL } from '~/ci/pipeline_details/constants';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import getPipelineStageJobsQuery from './graphql/queries/get_pipeline_stage_jobs.query.graphql';
import JobItem from './job_item.vue';

export default {
  name: 'PipelineStage',
  i18n: {
    loadingText: __('Loading...'),
    mergeTrainMessage: s__('Pipeline|Merge train pipeline jobs can not be retried'),
    stage: __('Stage'),
    stageJobsFetchError: __('There was a problem fetching the pipeline stage jobs.'),
    viewStageLabel: __('View Stage: %{title}'),
  },
  components: {
    JobItem,
    CiIcon,
    GlButton,
    GlDisclosureDropdown,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineEtag: {
      type: String,
      required: true,
    },
    pollInterval: {
      type: Number,
      required: false,
      default: PIPELINE_MINI_GRAPH_POLL_INTERVAL,
    },
    stage: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDropdownOpen: false,
      stageJobs: [],
      isPolling: false,
    };
  },
  apollo: {
    stageJobs: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineStageJobsQuery,
      variables() {
        return {
          id: this.stage.id,
        };
      },
      skip() {
        return !this.isPolling;
      },
      result() {
        this.$apollo.queries.stageJobs.startPolling(this.pollInterval);
      },
      update(data) {
        return data?.ciPipelineStage?.jobs?.nodes || [];
      },
      error(error) {
        createAlert({ message: this.$options.i18n.stageJobsFetchError });
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    dropdownHeaderText() {
      return `${this.$options.i18n.stage}: ${this.stage.name}`;
    },
    dropdownTooltipTitle() {
      return this.isDropdownOpen ? '' : `${this.stage.name}: ${this.stage.detailedStatus.tooltip}`;
    },
    isLoading() {
      return this.$apollo.queries.stageJobs.loading;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.stageJobs);
  },
  methods: {
    onHideDropdown() {
      this.isDropdownOpen = false;
      this.isPolling = false;
    },
    onShowDropdown() {
      this.isDropdownOpen = true;
      this.isPolling = true;
    },
    stageAriaLabel(title) {
      return sprintf(this.$options.i18n.viewStageLabel, { title });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    data-testid="pipeline-mini-graph-dropdown"
    :aria-label="stageAriaLabel(stage.name)"
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
        <ci-icon :status="stage.detailedStatus" :show-tooltip="false" :use-link="false" />
      </gl-button>
    </template>

    <template #header>
      <div
        data-testid="pipeline-stage-dropdown-menu-title"
        class="gl-flex gl-min-h-8 gl-items-center gl-border-b-1 gl-border-b-gray-200 !gl-p-4 gl-text-sm gl-font-bold gl-leading-1 gl-border-b-solid"
      >
        <span>{{ dropdownHeaderText }}</span>
      </div>
    </template>

    <div v-if="isLoading" class="gl-flex gl-gap-3 gl-px-4 gl-py-3">
      <gl-loading-icon size="sm" />
      <p class="gl-leading-normal">{{ $options.i18n.loadingText }}</p>
    </div>
    <ul
      v-else
      class="gl-m-0 gl-overflow-y-auto gl-p-0"
      data-testid="pipeline-mini-graph-dropdown-menu-list"
      @click.stop
    >
      <job-item
        v-for="job in stageJobs"
        :key="job.id"
        :dropdown-length="stageJobs.length"
        :job="job"
      />
    </ul>

    <template #footer>
      <div
        v-if="!isLoading && isMergeTrain"
        class="gl-border-t gl-px-4 gl-py-3 gl-text-sm gl-text-secondary"
        data-testid="merge-train-message"
      >
        {{ $options.i18n.mergeTrainMessage }}
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
