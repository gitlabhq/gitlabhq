<!-- eslint-disable vue/multi-word-component-names -->
<script>
import confetti from 'canvas-confetti';

export default {
  mounted() {
    confetti.create(this.$refs.canvas, {
      resize: true,
      useWorker: true,
      disableForReducedMotion: true,
    });

    this.basicCannon();
  },
  methods: {
    basicCannon() {
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.2 },
        scalar: 2,
        shapes: ['square'],
        colors: ['#FC6D26', '#6B4FBB', '#FDB997'],
        zIndex: 1045,
        gravity: 1.5,
      });
    },
  },
};
</script>

<template>
  <canvas ref="canvas" width="0" height="0"></canvas>
</template>
