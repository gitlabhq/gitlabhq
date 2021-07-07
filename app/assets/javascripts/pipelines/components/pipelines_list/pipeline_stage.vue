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

import { GlDropdown, GlLoadingIcon, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import eventHub from '../../event_hub';
import JobItem from './job_item.vue';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    GlDropdown,
    JobItem,
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
      isLoading: false,
      dropdownContent: [],
    };
  },
  computed: {
    triggerButtonClass() {
      return `ci-status-icon-${this.stage.status.group}`;
    },
    borderlessIcon() {
      return `${this.stage.status.icon}_borderless`;
    },
  },
  watch: {
    updateDropdown() {
      if (this.updateDropdown && this.isDropdownOpen() && !this.isLoading) {
        this.fetchJobs();
      }
    },
  },
  methods: {
    onShowDropdown() {
      eventHub.$emit('clickedDropdown');
      this.isLoading = true;
      this.fetchJobs();
    },
    fetchJobs() {
      axios
        .get(this.stage.dropdown_path)
        .then(({ data }) => {
          this.dropdownContent = data.latest_statuses;
          this.isLoading = false;
        })
        .catch(() => {
          this.$refs.dropdown.hide();
          this.isLoading = false;

          createFlash({
            message: __('Something went wrong on our end.'),
          });
        });
    },
    isDropdownOpen() {
      return this.$el.classList.contains('show');
    },
    pipelineActionRequestComplete() {
      // close the dropdown in MR widget
      this.$refs.dropdown.hide();

      // warn the pipelines table to update
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    v-gl-tooltip.hover.ds0
    data-testid="mini-pipeline-graph-dropdown"
    :title="stage.title"
    variant="link"
    :lazy="true"
    :popper-opts="{ placement: 'bottom' }"
    :toggle-class="['mini-pipeline-graph-dropdown-toggle', triggerButtonClass]"
    menu-class="mini-pipeline-graph-dropdown-menu"
    @show="onShowDropdown"
  >
    <template #button-content>
      <span class="gl-pointer-events-none">
        <gl-icon :name="borderlessIcon" />
      </span>
    </template>
    <gl-loading-icon v-if="isLoading" size="sm" />
    <ul
      v-else
      class="js-builds-dropdown-list scrollable-menu"
      data-testid="mini-pipeline-graph-dropdown-menu-list"
    >
      <li v-for="job in dropdownContent" :key="job.id">
        <job-item
          :dropdown-length="dropdownContent.length"
          :job="job"
          css-class-job-name="mini-pipeline-graph-dropdown-item"
          @pipelineActionRequestComplete="pipelineActionRequestComplete"
        />
      </li>
      <template v-if="isMergeTrain">
        <li class="gl-new-dropdown-divider" role="presentation">
          <hr role="separator" aria-orientation="horizontal" class="dropdown-divider" />
        </li>
        <li>
          <div
            class="gl-display-flex gl-align-items-center"
            data-testid="warning-message-merge-trains"
          >
            <div class="menu-item gl-font-sm gl-text-gray-300!">
              {{ s__('Pipeline|Merge train pipeline jobs can not be retried') }}
            </div>
          </div>
        </li>
      </template>
    </ul>
  </gl-dropdown>
</template>
