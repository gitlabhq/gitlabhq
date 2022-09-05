<script>
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { I18N_DETAILS_TITLE, I18N_LOCKED_RUNNER_DESCRIPTION } from '../constants';
import RunnerTypeBadge from './runner_type_badge.vue';
import RunnerStatusBadge from './runner_status_badge.vue';

export default {
  components: {
    GlIcon,
    GlSprintf,
    TimeAgo,
    RunnerTypeBadge,
    RunnerStatusBadge,
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
    paused() {
      return !this.runner.active;
    },
    heading() {
      const id = getIdFromGraphQLId(this.runner.id);
      return sprintf(I18N_DETAILS_TITLE, { runner_id: id });
    },
  },
  I18N_LOCKED_RUNNER_DESCRIPTION,
};
</script>
<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-gap-3 gl-flex-wrap gl-py-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
  >
    <div class="gl-display-flex gl-align-items-flex-start gl-gap-3 gl-flex-wrap">
      <runner-status-badge :runner="runner" />
      <runner-type-badge v-if="runner" :type="runner.runnerType" />
      <span>
        <template v-if="runner.createdAt">
          <gl-sprintf :message="__('%{runner} created %{timeago}')">
            <template #runner>
              <strong>{{ heading }}</strong>
              <gl-icon
                v-if="runner.locked"
                v-gl-tooltip="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
                name="lock"
                :aria-label="$options.I18N_LOCKED_RUNNER_DESCRIPTION"
              />
            </template>
            <template #timeago>
              <time-ago :time="runner.createdAt" />
            </template>
          </gl-sprintf>
        </template>
        <template v-else>
          <strong>{{ heading }}</strong>
        </template>
      </span>
    </div>
    <div class="gl-display-flex gl-gap-3 gl-flex-wrap"><slot name="actions"></slot></div>
  </div>
</template>
