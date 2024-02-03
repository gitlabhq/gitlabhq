<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';

export default {
  components: {
    GlSingleStat,
  },
  props: {
    stats: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap gl-mx-n3">
    <gl-single-stat
      v-for="(stat, index) in stats"
      :key="index"
      class="gl-w-full gl-flex-direction-column gl-align-items-center gl-justify-content-center gl-bg-white gl-border gl-border-gray-a-08 gl-mx-3 gl-p-3 gl-mt-3"
      :value="stat.value"
      :title="stat.title"
    />
  </div>
</template>
