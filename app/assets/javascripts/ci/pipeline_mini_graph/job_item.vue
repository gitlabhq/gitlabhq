<script>
import { GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import JobNameComponent from '~/ci/common/private/job_name_component.vue';

export default {
  name: 'JobItem',
  components: {
    JobNameComponent,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [delayedJobMixin],
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    item() {
      return {
        text: this.job.name,
        href: this.status?.detailsPath || '',
      };
    },
    status() {
      return this.job.detailedStatus || {};
    },
    tooltipText() {
      const { tooltip: statusTooltip } = this.status;

      if (this.isDelayedJob) {
        return sprintf(statusTooltip, { remainingTime: this.remainingTime });
      }
      return statusTooltip;
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item :item="item">
    <template #list-item>
      <job-name-component
        v-gl-tooltip.viewport.left
        class="-gl-my-2"
        :title="tooltipText"
        :name="job.name"
        :status="status"
      />
    </template>
  </gl-disclosure-dropdown-item>
</template>
