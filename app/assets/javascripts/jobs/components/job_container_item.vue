<script>
import { GlLink } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';
import { sprintf } from '~/locale';

export default {
  components: {
    CiIcon,
    Icon,
    GlLink,
  },
  directives: {
    tooltip,
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
      v-tooltip
      :href="job.status.details_path"
      :title="tooltipText"
      data-boundary="viewport"
      class="js-job-link"
    >
      <icon
        v-if="isActive"
        name="arrow-right"
        class="js-arrow-right icon-arrow-right position-absolute d-block"
      />

      <ci-icon :status="job.status" />

      <span>{{ job.name ? job.name : job.id }}</span>

      <icon v-if="job.retried" name="retry" class="js-retry-icon" />
    </gl-link>
  </div>
</template>
