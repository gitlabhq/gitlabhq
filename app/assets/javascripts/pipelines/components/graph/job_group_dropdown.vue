<script>
import $ from 'jquery';
import { GlTooltipDirective } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import JobItem from './job_item.vue';

/**
 * Renders the dropdown for the pipeline graph.
 *
 * The object provided as `group` corresponds to app/serializers/job_group_entity.rb.
 *
 */
export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    JobItem,
    CiIcon,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      const { name, status } = this.group;
      return `${name} - ${status.label}`;
    },
  },
  mounted() {
    this.stopDropdownClickPropagation();
  },
  methods: {
    /**
     * When the user right clicks or cmd/ctrl + click in the group name or the action icon
     * the dropdown should not be closed so we stop propagation
     * of the click event inside the dropdown.
     *
     * Since this component is rendered multiple times per page we need to guarantee we only
     * target the click event of this component.
     */
    stopDropdownClickPropagation() {
      $(
        '.js-grouped-pipeline-dropdown button, .js-grouped-pipeline-dropdown a.mini-pipeline-graph-dropdown-item',
        this.$el,
      ).on('click', e => {
        e.stopPropagation();
      });
    },

    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div class="ci-job-dropdown-container dropdown dropright">
    <button
      v-gl-tooltip.hover="{ boundary: 'viewport' }"
      :title="tooltipText"
      type="button"
      data-toggle="dropdown"
      data-display="static"
      class="dropdown-menu-toggle build-content"
    >
      <ci-icon :status="group.status" />

      <span
        class="ci-status-text text-truncate mw-70p gl-pl-1-deprecated-no-really-do-not-use-me d-inline-block align-bottom"
      >
        {{ group.name }}
      </span>

      <span class="dropdown-counter-badge"> {{ group.size }} </span>
    </button>

    <ul class="dropdown-menu big-pipeline-graph-dropdown-menu js-grouped-pipeline-dropdown">
      <li class="scrollable-menu">
        <ul>
          <li v-for="job in group.jobs" :key="job.id">
            <job-item
              :dropdown-length="group.size"
              :job="job"
              css-class-job-name="mini-pipeline-graph-dropdown-item"
              @pipelineActionRequestComplete="pipelineActionRequestComplete"
            />
          </li>
        </ul>
      </li>
    </ul>
  </div>
</template>
