<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { sprintf } from '~/locale';
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
    GlBadge,
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
      showTooltip: false,
    };
  },
  computed: {
    computedJobId() {
      return this.pipelineId > -1 ? `${this.group.name}-${this.pipelineId}` : '';
    },
    jobStatusText() {
      return this.jobItemTooltip(this.group);
    },
    placement() {
      // MR !49053:
      // We change the placement of the dropdown based on the breakpoint.
      // This is not an ideal solution, but rather a temporary solution
      // until we find a better solution in
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2615
      return this.isMobile ? 'left' : 'right-start';
    },
    moreActionsTooltip() {
      return !this.showTooltip ? this.jobStatusText : '';
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
    jobItemTooltip(job) {
      const { tooltip: statusTooltip } = job.status;
      const { text: statusText } = job.status;

      if (statusTooltip) {
        if (this.isDelayedJob) {
          return sprintf(statusTooltip, { remainingTime: job.remainingTime });
        }
        return statusTooltip;
      }
      return statusText;
    },
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
    :title="moreActionsTooltip"
    class="ci-job-group-dropdown"
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

    <gl-disclosure-dropdown-item
      v-for="job in group.jobs"
      :key="job.id"
      v-gl-tooltip.viewport.left="{
        title: jobItemTooltip(job),
        customClass: 'ci-job-component-tooltip',
      }"
      :item="jobItem(job)"
    >
      <template #list-item>
        <job-item
          :is-link="false"
          :job="job"
          :type="$options.jobItemTypes.singleJob"
          css-class-job-name="gl-p-3"
          hide-tooltip
          @pipelineActionRequestComplete="pipelineActionRequestComplete"
        />
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
