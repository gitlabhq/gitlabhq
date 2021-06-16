<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  components: {
    CiIcon,
    GlIcon,
    GlLink,
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
    isActive: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tooltipText() {
      const { name, status } = this.job;
      const text = `${name} - ${status.tooltip}`;

      if (this.isDelayedJob) {
        return sprintf(text, { remainingTime: this.remainingTime });
      }

      return text;
    },
    jobName() {
      return this.job.name ? this.job.name : this.job.id;
    },
    classes() {
      return {
        retried: this.job.retried,
        'gl-font-weight-bold': this.isActive,
      };
    },
    dataTestId() {
      return this.isActive ? 'active-job' : null;
    },
  },
};
</script>

<template>
  <div class="build-job gl-relative" :class="classes">
    <gl-link
      v-gl-tooltip.left.viewport
      :href="job.status.details_path"
      :title="tooltipText"
      class="gl-display-flex gl-align-items-center"
      :data-testid="dataTestId"
    >
      <gl-icon
        v-if="isActive"
        name="arrow-right"
        class="icon-arrow-right gl-absolute gl-display-block"
      />

      <ci-icon :status="job.status" />

      <span class="gl-text-truncate gl-w-full">{{ jobName }}</span>

      <gl-icon v-if="job.retried" name="retry" />
    </gl-link>
  </div>
</template>
