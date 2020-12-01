<script>
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
  methods: {
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
      class="dropdown-menu-toggle build-content gl-build-content"
    >
      <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
        <span class="gl-display-flex gl-align-items-center gl-w-90">
          <ci-icon :status="group.status" :size="24" />

          <span class="gl-text-truncate mw-70p gl-pl-3 gl-display-inline-block">
            {{ group.name }}
          </span>
        </span>

        <span class="gl-font-weight-100 gl-font-size-lg gl-pr-2"> {{ group.size }} </span>
      </div>
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
