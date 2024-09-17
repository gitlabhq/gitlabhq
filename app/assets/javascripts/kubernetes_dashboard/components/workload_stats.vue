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
  <div class="-gl-mx-3 gl-flex gl-flex-wrap sm:gl-flex-nowrap">
    <gl-single-stat
      v-for="(stat, index) in stats"
      :key="index"
      class="gl-border gl-mx-3 gl-mt-3 gl-w-full gl-cursor-pointer gl-flex-col gl-items-center gl-justify-center gl-border-alpha-dark-8 gl-bg-white gl-p-3"
      :value="stat.value"
      :title="stat.title"
      :class="{ 'gl-shadow-inner-b-2-blue-500': active === stat.title }"
      @click="select(stat.title)"
    />
  </div>
</template>
