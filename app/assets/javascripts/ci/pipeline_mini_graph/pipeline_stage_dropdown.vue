<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDropdownDivider,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagStagePath } from '~/ci/pipeline_details/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { PIPELINE_POLL_INTERVAL_DEFAULT, FAILED_STATUS } from '~/ci/constants';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import getPipelineStageJobsQuery from './graphql/queries/get_pipeline_stage_jobs.query.graphql';

export default {
  name: 'PipelineStageDropdown',
  components: {
    CiIcon,
    GlButton,
    GlDisclosureDropdown,
    GlDropdownDivider,
    GlLoadingIcon,
    JobDropdownItem,
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
    stage: {
      type: Object,
      required: true,
    },
  },
  emits: ['jobActionExecuted', 'miniGraphStageClick'],
  data() {
    return {
      isDropdownOpen: false,
      stageJobs: [],
    };
  },
  apollo: {
    stageJobs: {
      context() {
        return getQueryHeaders(this.graphqlEtag);
      },
      query: getPipelineStageJobsQuery,
      variables() {
        return {
          id: this.stage.id,
        };
      },
      skip() {
        return !this.isDropdownOpen;
      },
      pollInterval: PIPELINE_POLL_INTERVAL_DEFAULT,
      update(data) {
        return data?.ciPipelineStage?.jobs?.nodes || [];
      },
      error(error) {
        createAlert({
          message: s__('Pipelines|There was a problem fetching the pipeline stage jobs.'),
        });
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    dropdownHeaderText() {
      return sprintf(__('Stage: %{stageName}'), { stageName: this.stage.name });
    },
    dropdownTooltipTitle() {
      return this.isDropdownOpen ? '' : `${this.stage.name}: ${this.stage.detailedStatus.tooltip}`;
    },
    failedJobs() {
      return this.stageJobs.filter((job) => job.detailedStatus.group === FAILED_STATUS);
    },
    graphqlEtag() {
      return graphqlEtagStagePath('/api/graphql', getIdFromGraphQLId(this.stage.id));
    },
    hasFailedJobs() {
      return Boolean(this.failedJobs.length);
    },
    hasPassedJobs() {
      return Boolean(this.passedJobs.length);
    },
    isLoading() {
      return this.$apollo.queries.stageJobs.loading;
    },
    passedJobs() {
      return this.stageJobs.filter((job) => job.detailedStatus.group !== FAILED_STATUS);
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.stageJobs);
  },
  methods: {
    onHideDropdown() {
      this.isDropdownOpen = false;
      this.$apollo.queries.stageJobs.stopPolling();
    },
    onShowDropdown() {
      this.isDropdownOpen = true;
      this.$apollo.queries.stageJobs.startPolling(PIPELINE_POLL_INTERVAL_DEFAULT);

      // used for tracking in the pipeline table
      this.$emit('miniGraphStageClick');
    },
    stageAriaLabel(title) {
      return sprintf(__('View Stage: %{title}'), { title });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    data-testid="pipeline-mini-graph-dropdown"
    :aria-label="stageAriaLabel(stage.name)"
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
        <ci-icon :status="stage.detailedStatus" :show-tooltip="false" :use-link="false" />
      </gl-button>
    </template>

    <template #header>
      <div
        data-testid="pipeline-stage-dropdown-menu-title"
        class="gl-flex gl-min-h-8 gl-items-center gl-border-b-1 gl-border-b-dropdown !gl-p-4 gl-text-sm gl-font-bold gl-leading-1 gl-border-b-solid"
      >
        <span>{{ dropdownHeaderText }}</span>
      </div>
    </template>

    <div v-if="isLoading" class="gl-flex gl-gap-3 gl-px-4 gl-py-3">
      <gl-loading-icon size="sm" />
      <span class="gl-leading-normal">{{ __('Loading...') }}</span>
    </div>
    <ul
      v-else
      class="gl-m-0 gl-w-34 gl-overflow-y-auto gl-p-0"
      data-testid="pipeline-mini-graph-dropdown-menu-list"
      @click.stop
    >
      <span v-if="hasFailedJobs" class="gl-flex gl-px-4 gl-py-3 gl-text-sm gl-font-bold">
        {{ s__('Pipelines|Failed jobs') }}
      </span>
      <job-dropdown-item
        v-for="job in failedJobs"
        :key="job.id"
        :job="job"
        @jobActionExecuted="$emit('jobActionExecuted')"
      />
      <gl-dropdown-divider v-if="hasPassedJobs && hasFailedJobs" />
      <job-dropdown-item
        v-for="job in passedJobs"
        :key="job.id"
        :job="job"
        @jobActionExecuted="$emit('jobActionExecuted')"
      />
    </ul>

    <template #footer>
      <div
        v-if="!isLoading && isMergeTrain"
        class="gl-border-t gl-px-4 gl-py-3 gl-text-sm gl-text-subtle"
        data-testid="merge-train-message"
      >
        {{ s__('Pipeline|Merge train pipeline jobs can not be retried') }}
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
