<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import { JOB_DROPDOWN } from '../constants';
import JobItem from './job_item.vue';

/**
 * Renders the dropdown for the pipeline graph.
 *
 * The object provided as `group` corresponds to app/serializers/job_group_entity.rb.
 *
 */
export default {
  components: {
    JobDropdownItem,
    JobItem,
    GlBadge,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: false,
      default: -1,
    },
    cssClassJobName: {
      type: [String, Array],
      required: false,
      default: '',
    },
    stageName: {
      type: String,
      required: false,
      default: '',
    },
  },
  jobItemTypes: {
    jobDropdown: JOB_DROPDOWN,
  },
  data() {
    return {
      isMobile: false,
      showTooltip: false,
    };
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.group.name}-${this.pipelineId}` : '';
    },
    dropdownTooltip() {
      return !this.showTooltip ? this.group?.status?.tooltip || this.group?.status?.text : '';
    },
    placement() {
      // MR !49053:
      // We change the placement of the dropdown based on the breakpoint.
      // This is not an ideal solution, but rather a temporary solution
      // until we find a better solution in
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2615
      return this.isMobile ? 'bottom-start' : 'right-start';
    },
  },
  methods: {
    handleResize() {
      this.isMobile = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
    showDropdown() {
      this.showTooltip = true;
    },
    hideDropdown() {
      this.showTooltip = false;
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :id="computedJobId"
    v-gl-resize-observer="handleResize"
    v-gl-tooltip.viewport.left="{ customClass: 'ci-job-component-tooltip' }"
    :title="dropdownTooltip"
    block
    fluid-width
    :placement="placement"
    data-testid="job-dropdown-container"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template #toggle>
      <button type="button" :class="cssClassJobName" class="gl-w-full gl-bg-transparent gl-pr-4">
        <div class="gl-flex gl-items-stretch gl-justify-between">
          <job-item
            :type="$options.jobItemTypes.jobDropdown"
            :job="group"
            :stage-name="stageName"
            hide-tooltip
          />
          <gl-badge variant="muted" class="-gl-ml-5 -gl-mr-2 gl-self-center">
            {{ group.size }}
          </gl-badge>
        </div>
      </button>
    </template>
    <ul class="gl-m-0 gl-w-34 gl-overflow-y-auto gl-p-0" @click.stop>
      <job-dropdown-item
        v-for="job in group.jobs"
        :key="job.id"
        :job="job"
        @jobActionExecuted="$emit('pipelineActionRequestComplete')"
      />
    </ul>
  </gl-disclosure-dropdown>
</template>
