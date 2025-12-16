<script>
import { GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
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
      return Boolean(this.status?.action?.id && this.status?.action?.icon);
    },
    item() {
      return {
        text: this.job.name,
        href: this.status?.detailsPath || this.status?.deploymentDetailsPath || '',
      };
    },
    status() {
      return this.job.detailedStatus || this.job.status;
    },
    isFailed() {
      return this.status?.group === 'failed';
    },
    tooltipText() {
      const statusTooltip = capitalizeFirstCharacter(this.status?.tooltip);

      if (this.isDelayedJob) {
        return sprintf(statusTooltip, { remainingTime: this.remainingTime });
      }
      return statusTooltip;
    },
    hasUnauthorizedManualAction() {
      return !this.status?.action && this.status?.group === 'manual';
    },
    unauthorizedManualAction() {
      /*
        The action object is not available when the user cannot run the action.
        So we can show the correct icon, extract the action name from the label instead:
        "manual play action (not allowed)" or "manual stop action (not allowed)"
      */
      return {
        title: __('You are not authorized to run this manual job'),
        icon: this.status?.label?.split(' ')[1],
        confirmationMessage: null,
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item
    :item="item"
    class="ci-job-component"
    :class="{ 'ci-job-item-failed': isFailed }"
    data-testid="ci-job-item"
  >
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
        <job-action-button
          v-if="hasUnauthorizedManualAction"
          disabled
          :job-id="job.id"
          :job-action="unauthorizedManualAction"
          :job-name="job.name"
          class="gl-ml-6"
        />
      </div>
    </template>
  </gl-disclosure-dropdown-item>
</template>
