<script>
import { GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import JobNameComponent from '~/ci/common/private/job_name_component.vue';
import JobActionButton from './job_action_button.vue';

export default {
  name: 'JobItem',
  components: {
    JobActionButton,
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
    hasJobAction() {
      return Boolean(this.status?.action?.id);
    },
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
      const statusTooltip = capitalizeFirstCharacter(this.status?.tooltip);

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
      <div class="gl-flex -gl-my-2 gl-h-6">
        <job-name-component
          v-gl-tooltip.viewport.left
          class="-gl-my-2"
          :title="tooltipText"
          :name="job.name"
          :status="status"
        />
        <job-action-button
          v-if="hasJobAction"
          :job-id="job.id"
          :job-action="status.action"
          :job-name="job.name"
        />
      </div>
    </template>
  </gl-disclosure-dropdown-item>
</template>
