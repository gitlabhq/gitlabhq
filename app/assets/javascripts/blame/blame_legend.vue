<script>
export default {
  name: 'BlameLegend',
  legendCount: 10,
};
</script>
<template>
  <div class="file-blame-legend gl-mt-2" aria-hidden="true">
    <span class="left-label">{{ s__('Blame|Newer') }}</span>
    <span
      v-for="index in $options.legendCount"
      :key="index"
      :class="`legend-box gl-mr-2 legend-box-${index - 1}`"
    ></span>
    <span class="right-label">{{ s__('Blame|Older') }}</span>
  </div>
</template>
