<script>
export default {
  name: 'TrackLine',
  props: {
    track: {
      type: Object,
      required: true,
    },
  },
  methods: {
    strokeDashArray(type) {
      if (type === 'dashed') return '6, 3';
      if (type === 'dotted') return '3, 3';
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
        :stroke-dasharray="strokeDashArray(track.lineStyle)"
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

