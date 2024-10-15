<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import PageHeading from '~/vue_shared/components/page_heading.vue';
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
    PageHeading,
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
  <page-heading :heading="name">
    <template #description>
      <div class="gl-flex gl-flex-wrap gl-items-start gl-gap-3">
        <runner-status-badge :contacted-at="runner.contactedAt" :status="runner.status" />
        <runner-type-badge :type="runner.runnerType" />
        <runner-upgrade-status-badge :runner="runner" />
        <gl-icon
          v-if="runner.locked"
          v-gl-tooltip="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
          name="lock"
          :aria-label="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
        />
        <runner-created-at :runner="runner" class="-gl-mt-1" />
      </div>
    </template>

    <template #actions>
      <slot name="actions"></slot>
    </template>
  </page-heading>
</template>
