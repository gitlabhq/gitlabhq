<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import RunnerTypeIcon from '~/ci/runner/components/runner_type_icon.vue';
import { RUNNER_EMPTY_TEXT, RUNNER_NO_DESCRIPTION } from '../../constants';

export default {
  i18n: {
    emptyRunnerText: RUNNER_EMPTY_TEXT,
    noRunnerDescription: RUNNER_NO_DESCRIPTION,
  },
  components: {
    GlLink,
    RunnerTypeIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    runnerType() {
      return this.job.runner?.runnerType;
    },
  },
};
</script>

<template>
  <div class="gl-truncate">
    <span v-if="adminUrl">
      <runner-type-icon :type="runnerType" class="gl-align-middle" />
      <gl-link :href="adminUrl" data-testid="job-runner-link"> {{ description }} </gl-link>
    </span>
    <span v-else data-testid="empty-runner-text"> {{ $options.i18n.emptyRunnerText }}</span>
  </div>
</template>
