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

import { GlDropdown, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
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
    stage: __('Stage:'),
    viewStageLabel: __('View Stage: %{title}'),
  },
  dropdownPopperOpts: {
    placement: 'bottom',
    positionFixed: true,
  },
  components: {
    CiIcon,
    GlLoadingIcon,
    GlDropdown,
    LegacyJobItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
          this.$refs.dropdown.hide();
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
  <gl-dropdown
    ref="dropdown"
    v-gl-tooltip.hover.ds0
    v-gl-tooltip="stage.title"
    data-testid="mini-pipeline-graph-dropdown"
    variant="link"
    :aria-label="stageAriaLabel(stage.title)"
    :lazy="true"
    :popper-opts="$options.dropdownPopperOpts"
    :toggle-class="['gl-rounded-full!']"
    menu-class="mini-pipeline-graph-dropdown-menu"
    @hide="onHideDropdown"
    @show="onShowDropdown"
  >
    <template #button-content>
      <ci-icon :status="stage.status" :show-tooltip="false" :use-link="false" class="gl-mb-0!" />
    </template>
    <div v-if="isLoading" class="gl--flex-center gl-p-2" data-testid="pipeline-stage-loading-state">
      <gl-loading-icon size="sm" class="gl-mr-3" />
      <p class="gl-line-height-normal gl-mb-0">{{ $options.i18n.loadingText }}</p>
    </div>
    <ul
      v-else
      class="js-builds-dropdown-list scrollable-menu"
      data-testid="mini-pipeline-graph-dropdown-menu-list"
    >
      <div class="gl--flex-center gl-border-b gl-font-weight-bold gl-mb-3 gl-pb-3">
        <span class="gl-mr-1">{{ $options.i18n.stage }}</span>
        <span data-testid="pipeline-stage-dropdown-menu-title">{{ stageName }}</span>
      </div>
      <li v-for="job in dropdownContent" :key="job.id">
        <legacy-job-item
          :dropdown-length="dropdownContent.length"
          :job="job"
          css-class-job-name="pipeline-job-item"
        />
      </li>
      <template v-if="isMergeTrain">
        <li class="gl-dropdown-divider" role="presentation">
          <hr role="separator" aria-orientation="horizontal" class="dropdown-divider" />
        </li>
        <li>
          <div
            class="gl-display-flex gl-align-items-center"
            data-testid="warning-message-merge-trains"
          >
            <div class="menu-item gl-font-sm gl-text-gray-300!">
              {{ $options.i18n.mergeTrainMessage }}
            </div>
          </div>
        </li>
      </template>
    </ul>
  </gl-dropdown>
</template>
