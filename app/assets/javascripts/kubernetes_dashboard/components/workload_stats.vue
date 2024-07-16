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
  data() {
    return {
      active: '',
    };
  },
  methods: {
    select(item) {
      if (item === this.active) {
        this.active = '';
      } else {
        this.active = item;
      }

      this.$emit('select', this.active);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap -gl-mx-3">
    <gl-single-stat
      v-for="(stat, index) in stats"
      :key="index"
      class="gl-w-full gl-flex-col gl-items-center gl-justify-center gl-bg-white gl-border gl-border-gray-a-08 gl-mx-3 gl-p-3 gl-mt-3 gl-cursor-pointer"
      :value="stat.value"
      :title="stat.title"
      :class="{ 'gl-shadow-inner-b-2-blue-500': active === stat.title }"
      @click="select(stat.title)"
    />
  </div>
</template>
