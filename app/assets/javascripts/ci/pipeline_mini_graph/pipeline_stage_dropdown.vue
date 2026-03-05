<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlLoadingIcon,
  GlTooltipDirective,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { getQueryHeaders, toggleQueryPollingByVisibility } from '~/ci/pipeline_details/graph/utils';
import { graphqlEtagStagePath } from '~/ci/pipeline_details/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { PIPELINE_POLL_INTERVAL_DEFAULT, FAILED_STATUS } from '~/ci/constants';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import getPipelineStageJobsQuery from './graphql/queries/get_pipeline_stage_jobs.query.graphql';
import stageJobsUpdatedSubscription from './graphql/subscriptions/stage_jobs_updated.subscription.graphql';

const searchItemsThreshold = 12;

export default {
  name: 'PipelineStageDropdown',
  components: {
    CiIcon,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlLoadingIcon,
    GlSearchBoxByType,
    JobDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
  emits: ['job-action-executed', 'mini-graph-stage-click'],
  data() {
    return {
      isDropdownOpen: false,
      stageJobs: [],
      search: '',
      isSubscribed: false,
    };
  },
  apollo: {
    stageJobs: {
      context() {
        if (this.useRealTime) {
          return {
            featureCategory: 'continuous_integration',
          };
        }

        return {
          ...getQueryHeaders(this.graphqlEtag),
          featureCategory: 'continuous_integration',
        };
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
        if (this.useRealTime) {
          this.$apollo.queries.stageJobs.stopPolling();
        }
        return data?.ciPipelineStage?.jobs?.nodes || [];
      },
      result({ data }) {
        if (
          this.useRealTime &&
          this.isDropdownOpen &&
          !this.isSubscribed &&
          data?.ciPipelineStage
        ) {
          this.subscribeToJobUpdates();
        }
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
    searchedJobs() {
      return this.stageJobs.filter((job) =>
        job.name.toLowerCase().includes(this.search.toLowerCase()),
      );
    },
    searchVisible() {
      return !this.isLoading && this.stageJobs.length > searchItemsThreshold;
    },
    useRealTime() {
      return this.glFeatures?.pipelineMiniGraphSubscription;
    },
  },
  watch: {
    isDropdownOpen(isOpen) {
      if (this.useRealTime && !isOpen) {
        this.unsubscribeFromJobUpdates();
      }
    },
  },
  mounted() {
    if (!this.useRealTime) {
      toggleQueryPollingByVisibility(this.$apollo.queries.stageJobs);
    }
  },
  beforeDestroy() {
    this.unsubscribeFromJobUpdates();
  },
  methods: {
    onShowDropdown() {
      this.isDropdownOpen = true;
      // used for tracking in the pipeline table
      this.$emit('mini-graph-stage-click');
      if (!this.useRealTime) {
        this.$apollo.queries.stageJobs.startPolling(PIPELINE_POLL_INTERVAL_DEFAULT);
      }
    },
    onHideDropdown() {
      this.isDropdownOpen = false;
      this.search = '';
      this.$apollo.queries.stageJobs.stopPolling();
    },
    subscribeToJobUpdates() {
      if (!this.stage.id || this.isSubscribed) return;

      this.isSubscribed = true;

      this.jobSubscription = this.$apollo.queries.stageJobs.subscribeToMore({
        document: stageJobsUpdatedSubscription,
        variables: { stageId: this.stage.id },
        updateQuery: (previousData, { subscriptionData }) => {
          const updatedJob = subscriptionData.data?.ciStageUpdated;
          if (!updatedJob || !previousData?.ciPipelineStage) {
            return previousData;
          }

          return {
            ...previousData,
            ciPipelineStage: {
              ...previousData.ciPipelineStage,
              jobs: {
                ...previousData.ciPipelineStage.jobs,
                nodes: previousData.ciPipelineStage.jobs.nodes.map((job) =>
                  job.name === updatedJob.name ? updatedJob : job,
                ),
              },
            },
          };
        },
      });
    },
    unsubscribeFromJobUpdates() {
      if (this.jobSubscription) {
        this.jobSubscription?.unsubscribe();
        this.isSubscribed = false;
        this.jobSubscription = null;
      }
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
    <template #toggle="{ accessibilityAttributes }">
      <gl-button
        v-gl-tooltip.hover="dropdownTooltipTitle"
        v-bind="accessibilityAttributes"
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
        class="gl-border-b gl-flex gl-min-h-8 gl-items-center !gl-p-4 gl-text-sm gl-font-bold gl-leading-1 gl-border-b-solid"
      >
        <span>{{ dropdownHeaderText }}</span>
      </div>
      <gl-search-box-by-type
        v-if="searchVisible"
        v-model="search"
        class="pipeline-mini-graph-search"
        borderless
      />
    </template>

    <div v-if="isLoading" class="gl-flex gl-gap-3 gl-px-4 gl-py-3">
      <gl-loading-icon size="sm" />
      <span class="gl-leading-normal">{{ __('Loading…') }}</span>
    </div>
    <ul
      v-else
      class="gl-m-0 gl-w-34 gl-overflow-y-auto gl-p-0"
      data-testid="pipeline-mini-graph-dropdown-menu-list"
      @click.stop
    >
      <template v-if="search">
        <gl-disclosure-dropdown-group
          v-if="searchedJobs.length"
          key="searched-jobs"
          data-testid="searched-jobs"
        >
          <job-dropdown-item
            v-for="job in searchedJobs"
            :key="job.id + 'searched'"
            :job="job"
            @job-action-executed="$emit('job-action-executed')"
          />
        </gl-disclosure-dropdown-group>
      </template>
      <template v-else>
        <gl-disclosure-dropdown-group v-if="hasFailedJobs" class="gl-text-left">
          <template #group-label
            ><span class="gl-inline-block gl-w-full gl-text-left">{{
              s__('Pipelines|Failed jobs')
            }}</span></template
          >
          <job-dropdown-item
            v-for="job in failedJobs"
            :key="job.id"
            :job="job"
            @job-action-executed="$emit('job-action-executed')"
          />
        </gl-disclosure-dropdown-group>
        <gl-disclosure-dropdown-group
          v-if="hasPassedJobs"
          :bordered="hasFailedJobs"
          data-testid="passed-jobs"
        >
          <job-dropdown-item
            v-for="job in passedJobs"
            :key="job.id"
            :job="job"
            @job-action-executed="$emit('job-action-executed')"
          />
        </gl-disclosure-dropdown-group>
      </template>
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
