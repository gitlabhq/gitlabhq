<script>
import { GlLink, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import delayedJobMixin from '~/ci/mixins/delayed_job_mixin';
import { sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

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
        'retried gl-text-subtle': this.job.retried,
        'gl-font-bold': this.isActive,
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
      class="gl-flex gl-items-center gl-py-3 gl-pl-7"
      :data-testid="dataTestId"
    >
      <gl-icon
        v-if="isActive"
        name="arrow-right"
        :show-tooltip="false"
        class="icon-arrow-right gl-absolute gl-block"
      />

      <ci-icon :status="job.status" :show-tooltip="false" class="gl-mr-3" />

      <span class="gl-w-full gl-truncate">{{ jobName }}</span>

      <gl-icon v-if="job.retried" name="retry" class="gl-mr-4" />
    </gl-link>
  </div>
</template>
