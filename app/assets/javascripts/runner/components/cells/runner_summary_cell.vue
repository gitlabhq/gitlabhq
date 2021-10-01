<script>
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import RunnerName from '../runner_name.vue';

export default {
  components: {
    TooltipOnTruncate,
    RunnerName,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  computed: {
    description() {
      return this.runner.description;
    },
  },
};
</script>

<template>
  <div>
    <slot :runner="runner" name="runner-name">
      <runner-name :runner="runner" />
    </slot>
    <tooltip-on-truncate class="gl-display-block" :title="description" truncate-target="child">
      <div class="gl-text-truncate">
        {{ description }}
      </div>
    </tooltip-on-truncate>
  </div>
</template>
