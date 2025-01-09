<script>
import { GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import JobActionButton from './job_action_button.vue';
import JobNameComponent from './job_name_component.vue';

export default {
  name: 'JobDropdownItem',
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
  emits: ['jobActionExecuted'],
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
      return this.job.detailedStatus || this.job.status;
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
  <gl-disclosure-dropdown-item :item="item" class="ci-job-component" data-testid="ci-job-item">
    <template #list-item>
      <div class="-gl-my-2 gl-flex gl-items-center gl-justify-between">
        <job-name-component
          v-gl-tooltip.viewport.left
          :title="tooltipText"
          :name="job.name"
          :status="status"
          data-testid="job-name"
        />
        <job-action-button
          v-if="hasJobAction"
          class="gl-ml-6"
          :job-id="job.id"
          :job-action="status.action"
          :job-name="job.name"
          @jobActionExecuted="$emit('jobActionExecuted')"
        />
      </div>
    </template>
  </gl-disclosure-dropdown-item>
</template>
