<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { I18N_LOCKED_RUNNER_DESCRIPTION } from '../constants';
import { formatRunnerName } from '../utils';
import RunnerCreatedAt from './runner_created_at.vue';
import RunnerTypeBadge from './runner_type_badge.vue';
import RunnerStatusBadge from './runner_status_badge.vue';

export default {
  components: {
    GlIcon,
    RunnerCreatedAt,
    RunnerTypeBadge,
    RunnerStatusBadge,
    RunnerUpgradeStatusBadge: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_badge.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    name() {
      return formatRunnerName(this.runner);
    },
  },
  I18N_LOCKED_RUNNER_DESCRIPTION,
};
</script>
<template>
  <div class="gl-py-5">
    <div class="gl-display-flex gl-justify-content-space-between">
      <h1 class="gl-font-size-h-display gl-my-0">{{ name }}</h1>
      <slot name="actions"></slot>
    </div>
    <div class="gl-display-flex gl-align-items-flex-start gl-gap-3 gl-flex-wrap gl-mt-3">
      <runner-status-badge :contacted-at="runner.contactedAt" :status="runner.status" />
      <runner-type-badge :type="runner.runnerType" />
      <runner-upgrade-status-badge :runner="runner" />
      <gl-icon
        v-if="runner.locked"
        v-gl-tooltip="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
        name="lock"
        :aria-label="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
      />
      <runner-created-at :runner="runner" />
    </div>
  </div>
</template>
