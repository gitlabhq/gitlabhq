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
      width="15"
      height="6">
      <line
        :stroke-dasharray="stylizedLine"
        :stroke="track.lineColor"
        stroke-width="4"
        :x1="0"
        :x2="15"
        :y1="2"
        :y2="2"
      />
    </svg>
  </td>
</template>

