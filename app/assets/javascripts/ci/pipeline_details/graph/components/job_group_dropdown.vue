<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { reportToSentry } from '~/ci/utils';
import { JOB_DROPDOWN, SINGLE_JOB } from '../constants';
import JobItem from './job_item.vue';

/**
 * Renders the dropdown for the pipeline graph.
 *
 * The object provided as `group` corresponds to app/serializers/job_group_entity.rb.
 *
 */
export default {
  components: {
    JobItem,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
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
    singleJob: SINGLE_JOB,
  },
  data() {
    return {
      isMobile: false,
    };
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.group.name}-${this.pipelineId}` : '';
    },
    jobGroupClasses() {
      return [this.cssClassJobName, `job-${this.group.status.group}`];
    },
    jobStatusText() {
      const textBuilder = [];
      const { tooltip: statusTooltip } = this.group.status;

      if (statusTooltip) {
        const statusText = statusTooltip.charAt(0).toUpperCase() + statusTooltip.slice(1);
        textBuilder.push(statusText);
      } else {
        textBuilder.push(this.group.status?.text);
      }

      return textBuilder.join(' ');
    },
    placement() {
      // MR !49053:
      // We change the placement of the dropdown based on the breakpoint.
      // This is not an ideal solution, but rather a temporary solution
      // until we find a better solution in
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2615
      return this.isMobile ? 'left' : 'right-start';
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('job_group_dropdown', `error: ${err}, info: ${info}`);
  },
  methods: {
    pipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
    jobItem(job) {
      return {
        text: job.name,
        href: job.status?.detailsPath,
      };
    },
    handleResize() {
      this.isMobile = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    :id="computedJobId"
    v-gl-resize-observer="handleResize"
    v-gl-tooltip.viewport.left
    :title="jobStatusText"
    class="ci-job-group-dropdown"
    block
    fluid-width
    :placement="placement"
    data-testid="job-dropdown-container"
  >
    <template #toggle>
      <button type="button" :class="jobGroupClasses" class="gl-w-full gl-pr-4">
        <div class="gl-display-flex gl-align-items-stretch gl-justify-content-space-between">
          <job-item
            :type="$options.jobItemTypes.jobDropdown"
            :job="group"
            :stage-name="stageName"
            hide-tooltip
          />

          <div class="gl-font-weight-100 gl-font-size-lg gl-ml-n4 gl-align-self-center">
            {{ group.size }}
          </div>
        </div>
      </button>
    </template>

    <gl-disclosure-dropdown-item v-for="job in group.jobs" :key="job.id" :item="jobItem(job)">
      <template #list-item>
        <job-item
          :is-link="false"
          :job="job"
          :type="$options.jobItemTypes.singleJob"
          css-class-job-name="gl-p-3"
          @pipelineActionRequestComplete="pipelineActionRequestComplete"
        />
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
