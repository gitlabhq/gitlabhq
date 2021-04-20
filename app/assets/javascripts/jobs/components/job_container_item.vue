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
  },
};
</script>

<template>
  <div
    class="build-job position-relative"
    :class="{
      retried: job.retried,
      active: isActive,
    }"
  >
    <gl-link
      v-gl-tooltip:tooltip-container.left
      :href="job.status.details_path"
      :title="tooltipText"
      class="js-job-link gl-display-flex gl-align-items-center"
    >
      <gl-icon
        v-if="isActive"
        name="arrow-right"
        class="js-arrow-right icon-arrow-right position-absolute d-block"
      />

      <ci-icon :status="job.status" />

      <span class="text-truncate w-100">{{ job.name ? job.name : job.id }}</span>

      <gl-icon v-if="job.retried" name="retry" />
    </gl-link>
  </div>
</template>
