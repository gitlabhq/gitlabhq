<script>
export default {
  name: 'TrackLine',
  props: {
    track: {
      type: Object,
      required: true,
    },
  },
  computed: {
    stylizedLine() {
      if (this.track.lineStyle === 'dashed') return '6, 3';
      if (this.track.lineStyle === 'dotted') return '3, 3';
      return null;
    },
  },
};
</script>
<template>
  <td>
    <svg
      width="16"
      height="8">
      <line
        :stroke-dasharray="stylizedLine"
        :stroke="track.lineColor"
        stroke-width="4"
        :x1="0"
        :x2="16"
        :y1="4"
        :y2="4"
      />
    </svg>
  </td>
</template>

