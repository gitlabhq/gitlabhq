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
import $ from 'jquery';
import { GlDropdown, GlLoadingIcon, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { deprecatedCreateFlash as Flash } from '~/flash';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import axios from '~/lib/utils/axios_utils';
import eventHub from '../../event_hub';
import JobItem from '../graph/job_item.vue';
import { PIPELINES_TABLE } from '../../constants';

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
  mixins: [glFeatureFlagsMixin()],
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

    type: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      dropdownContent: [],
    };
  },
  computed: {
    isCiMiniPipelineGlDropdown() {
      // Feature flag ci_mini_pipeline_gl_dropdown
      // See more at https://gitlab.com/gitlab-org/gitlab/-/issues/300400
      return this.glFeatures?.ciMiniPipelineGlDropdown;
    },
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
  updated() {
    if (!this.isCiMiniPipelineGlDropdown && this.dropdownContent.length) {
      this.stopDropdownClickPropagation();
    }
  },
  methods: {
    onShowDropdown() {
      eventHub.$emit('clickedDropdown');
      this.isLoading = true;
      this.fetchJobs();
    },
    onClickStage() {
      if (!this.isDropdownOpen()) {
        eventHub.$emit('clickedDropdown');
        this.isLoading = true;
        this.fetchJobs();
      }
    },
    fetchJobs() {
      axios
        .get(this.stage.dropdown_path)
        .then(({ data }) => {
          this.dropdownContent = data.latest_statuses;
          this.isLoading = false;
        })
        .catch(() => {
          if (this.isCiMiniPipelineGlDropdown) {
            this.$refs.stageGlDropdown.hide();
          } else {
            this.closeDropdown();
          }
          this.isLoading = false;

          Flash(__('Something went wrong on our end.'));
        });
    },
    /**
     * When the user right clicks or cmd/ctrl + click in the job name
     * the dropdown should not be closed and the link should open in another tab,
     * so we stop propagation of the click event inside the dropdown.
     *
     * Since this component is rendered multiple times per page we need to guarantee we only
     * target the click event of this component.
     *
     * Note: This should be removed once ci_mini_pipeline_gl_dropdown FF is removed as true.
     */
    stopDropdownClickPropagation() {
      $(
        '.js-builds-dropdown-list button, .js-builds-dropdown-list a.mini-pipeline-graph-dropdown-item',
        this.$el,
      ).on('click', (e) => {
        e.stopPropagation();
      });
    },
    closeDropdown() {
      if (this.isDropdownOpen()) {
        $(this.$refs.dropdown).dropdown('toggle');
      }
    },
    isDropdownOpen() {
      return this.$el.classList.contains('show');
    },
    pipelineActionRequestComplete() {
      if (this.type === PIPELINES_TABLE) {
        // warn the table to update
        eventHub.$emit('refreshPipelinesTable');
        return;
      }
      // close the dropdown in mr widget
      if (this.isCiMiniPipelineGlDropdown) {
        this.$refs.stageGlDropdown.hide();
      } else {
        $(this.$refs.dropdown).dropdown('toggle');
      }
    },
  },
};
</script>

<template>
  <div class="dropdown">
    <gl-dropdown
      v-if="isCiMiniPipelineGlDropdown"
      ref="stageGlDropdown"
      v-gl-tooltip.hover
      data-testid="mini-pipeline-graph-dropdown"
      :title="stage.title"
      variant="link"
      :lazy="true"
      :popper-opts="{ placement: 'bottom' }"
      :toggle-class="['mini-pipeline-graph-gl-dropdown-toggle', triggerButtonClass]"
      menu-class="mini-pipeline-graph-dropdown-menu"
      @show="onShowDropdown"
    >
      <template #button-content>
        <span class="gl-pointer-events-none">
          <gl-icon :name="borderlessIcon" />
        </span>
      </template>
      <gl-loading-icon v-if="isLoading" />
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
      </ul>
    </gl-dropdown>

    <template v-else>
      <button
        id="stageDropdown"
        ref="dropdown"
        v-gl-tooltip.hover
        :class="triggerButtonClass"
        :title="stage.title"
        class="mini-pipeline-graph-dropdown-toggle"
        data-testid="mini-pipeline-graph-dropdown-toggle"
        data-toggle="dropdown"
        data-display="static"
        type="button"
        aria-haspopup="true"
        aria-expanded="false"
        @click="onClickStage"
      >
        <span :aria-label="stage.title" aria-hidden="true" class="gl-pointer-events-none">
          <gl-icon :name="borderlessIcon" />
        </span>
      </button>

      <div
        class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container"
        aria-labelledby="stageDropdown"
      >
        <gl-loading-icon v-if="isLoading" />
        <ul v-else class="js-builds-dropdown-list scrollable-menu">
          <li v-for="job in dropdownContent" :key="job.id">
            <job-item
              :dropdown-length="dropdownContent.length"
              :job="job"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
              @pipelineActionRequestComplete="pipelineActionRequestComplete"
            />
          </li>
        </ul>
      </div>
    </template>
  </div>
</template>
