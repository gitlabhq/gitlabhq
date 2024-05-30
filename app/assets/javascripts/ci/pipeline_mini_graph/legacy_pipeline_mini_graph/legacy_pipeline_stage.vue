<script>
/**
 * Renders each stage of the pipeline mini graph.
 *
 * Given the provided endpoint will make a request to
 * fetch the dropdown data when the stage is clicked.
 *
 * Request is made inside this component to make it reusable between:
 * 1. Pipelines main table
 * 2. Pipelines table in commit and Merge request views
 * 3. Merge request widget
 * 4. Commit widget
 */

import { GlDisclosureDropdown, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { createAlert } from '~/alert';
import eventHub from '~/ci/event_hub';
import axios from '~/lib/utils/axios_utils';
import { __, s__, sprintf } from '~/locale';
import LegacyJobItem from './legacy_job_item.vue';

export default {
  i18n: {
    errorMessage: __('Something went wrong on our end.'),
    loadingText: __('Loading...'),
    mergeTrainMessage: s__('Pipeline|Merge train pipeline jobs can not be retried'),
    stage: __('Stage'),
    viewStageLabel: __('View Stage: %{title}'),
  },
  components: {
    CiIcon,
    GlLoadingIcon,
    GlDisclosureDropdown,
    GlButton,
    LegacyJobItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  tooltipConfig: {
    boundary: 'viewport',
    placement: 'top',
    customClass: 'gl-pointer-events-none',
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isDropdownOpen: false,
      isLoading: false,
      dropdownContent: [],
      stageName: '',
    };
  },
  watch: {
    updateDropdown() {
      if (this.updateDropdown && this.isDropdownOpen && !this.isLoading) {
        this.fetchJobs();
      }
    },
  },
  methods: {
    onHideDropdown() {
      this.isDropdownOpen = false;
    },
    onShowDropdown() {
      eventHub.$emit('clickedDropdown');
      this.isDropdownOpen = true;
      this.isLoading = true;
      this.fetchJobs();

      // used for tracking and is separate from event hub
      // to avoid complexity with mixin
      this.$emit('miniGraphStageClick');
    },
    fetchJobs() {
      axios
        .get(this.stage.dropdown_path)
        .then(({ data }) => {
          this.dropdownContent = data.latest_statuses;
          this.stageName = data.name;
          this.isLoading = false;
        })
        .catch(() => {
          this.$refs.dropdown.close();
          this.isLoading = false;

          createAlert({
            message: this.$options.i18n.errorMessage,
          });
        });
    },
    stageAriaLabel(title) {
      return sprintf(this.$options.i18n.viewStageLabel, { title });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    data-testid="mini-pipeline-graph-dropdown"
    class="mini-pipeline-graph-dropdown"
    variant="link"
    :aria-label="stageAriaLabel(stage.title)"
    no-caret
    @hidden="onHideDropdown"
    @shown="onShowDropdown"
  >
    <template #toggle>
      <gl-button
        v-gl-tooltip.ds0="$options.tooltipConfig"
        :title="isDropdownOpen ? '' : stage.title"
        variant="link"
        class="gl-rounded-full!"
        data-testid="mini-pipeline-graph-dropdown-toggle"
      >
        <ci-icon :status="stage.status" :show-tooltip="false" :use-link="false" class="gl-mb-0!" />
      </gl-button>
    </template>

    <template #header>
      <div
        class="gl-display-flex gl-align-items-center gl-p-4! gl-min-h-8 gl-border-b-1 gl-border-b-solid gl-border-b-gray-200 gl-font-sm gl-font-bold gl-leading-1"
      >
        <template v-if="isLoading">
          <span>{{ $options.i18n.stage }}</span>
        </template>
        <template v-else>
          <span class="gl-mr-1">{{ $options.i18n.stage }}:</span>
          <span data-testid="pipeline-stage-dropdown-menu-title">{{ stageName }}</span>
        </template>
      </div>
    </template>

    <div
      v-if="isLoading"
      class="gl-display-flex gl-py-3 gl-px-4"
      data-testid="pipeline-stage-loading-state"
    >
      <gl-loading-icon size="sm" class="gl-mr-3" />
      <p class="gl-leading-normal gl-mb-0">{{ $options.i18n.loadingText }}</p>
    </div>
    <ul
      v-else
      class="mini-pipeline-graph-dropdown-menu gl-overflow-y-auto gl-m-0 gl-p-0"
      data-testid="mini-pipeline-graph-dropdown-menu-list"
      @click.stop
    >
      <legacy-job-item
        v-for="job in dropdownContent"
        :key="job.id"
        :dropdown-length="dropdownContent.length"
        :job="job"
        css-class-job-name="pipeline-job-item"
      />
    </ul>

    <template #footer>
      <div
        v-if="!isLoading && isMergeTrain"
        class="gl-font-sm gl-text-secondary gl-py-3 gl-px-4 gl-border-t"
        data-testid="warning-message-merge-trains"
      >
        {{ $options.i18n.mergeTrainMessage }}
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
