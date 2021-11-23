<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';

export default {
  components: {
    GlSingleStat,
  },
};
</script>
<template>
  <gl-single-stat
    v-bind="$attrs"
    variant="success"
    :title="s__('Runners|Online Runners')"
    :meta-text="s__('Runners|online')"
  />
</template>
