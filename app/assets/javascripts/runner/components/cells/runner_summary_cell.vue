<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import RunnerName from '../runner_name.vue';
import RunnerTypeBadge from '../runner_type_badge.vue';

import { I18N_LOCKED_RUNNER_DESCRIPTION } from '../../constants';

export default {
  components: {
    GlIcon,
    TooltipOnTruncate,
    RunnerName,
    RunnerTypeBadge,
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
    runnerType() {
      return this.runner.runnerType;
    },
    locked() {
      return this.runner.locked;
    },
    description() {
      return this.runner.description;
    },
    ipAddress() {
      return this.runner.ipAddress;
    },
  },
  i18n: {
    I18N_LOCKED_RUNNER_DESCRIPTION,
  },
};
</script>

<template>
  <div>
    <slot :runner="runner" name="runner-name">
      <runner-name :runner="runner" />
    </slot>

    <runner-type-badge :type="runnerType" size="sm" />
    <gl-icon
      v-if="locked"
      v-gl-tooltip
      :title="$options.i18n.I18N_LOCKED_RUNNER_DESCRIPTION"
      name="lock"
    />
    <tooltip-on-truncate class="gl-display-block gl-text-truncate" :title="description">
      {{ description }}
    </tooltip-on-truncate>
    <tooltip-on-truncate
      v-if="ipAddress"
      class="gl-display-block gl-text-truncate"
      :title="ipAddress"
    >
      <span class="gl-md-display-none gl-lg-display-inline">{{ __('IP Address') }}</span>
      <strong>{{ ipAddress }}</strong>
    </tooltip-on-truncate>
  </div>
</template>
