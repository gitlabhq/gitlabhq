<script>
import { GlLink } from '@gitlab/ui';
import { RUNNER_EMPTY_TEXT, RUNNER_NO_DESCRIPTION } from '~/pages/admin/jobs/components/constants';

export default {
  i18n: {
    emptyRunnerText: RUNNER_EMPTY_TEXT,
    noRunnerDescription: RUNNER_NO_DESCRIPTION,
  },
  components: {
    GlLink,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  computed: {
    adminUrl() {
      return this.job.runner?.adminUrl;
    },
    description() {
      return this.job.runner?.description
        ? this.job.runner.description
        : this.$options.i18n.noRunnerDescription;
    },
  },
};
</script>

<template>
  <div class="gl-text-truncate">
    <gl-link v-if="adminUrl" :href="adminUrl">
      {{ description }}
    </gl-link>
    <span v-else data-testid="empty-runner-text"> {{ $options.i18n.emptyRunnerText }}</span>
  </div>
</template>
