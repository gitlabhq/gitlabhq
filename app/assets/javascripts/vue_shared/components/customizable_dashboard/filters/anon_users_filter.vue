<script>
import { GlToggle, GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'AnonUsersFilter',
  components: {
    GlToggle,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full gl-flex-row gl-gap-3 sm:gl-w-auto">
    <gl-toggle
      :value="value"
      :label="s__('Analytics|Exclude anonymous users')"
      label-position="left"
      @change="$emit('change', $event)"
    />
    <gl-icon
      v-gl-tooltip
      :title="s__('Analytics|View metrics only for users who have consented to activity tracking.')"
      name="information-o"
      class="gl-self-center"
      variant="subtle"
    />
  </div>
</template>
