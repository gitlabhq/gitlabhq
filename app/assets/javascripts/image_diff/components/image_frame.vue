<script>
  export default {
    name: 'imageFrame',
    data() {
      return {
        imageLoaded: false,
      };
    },
    props: {
      src: {
        type: String,
        required: true,
      },
      alt: {
        type: String,
        required: true,
      },
      className: {
        type: String,
        required: false,
      },
      coordinates: {
        type: Array,
        required: false,
      },
    },
    methods: {
      load(event) {
        this.imageLoaded = true;
        this.$emit('imageLoaded', event);
      },
      click() {
        this.$emit('click', event);
      },
      styleCoordinate(coordinate) {
        return `left: ${coordinate.x}px; top: ${coordinate.y}px`;
      },
    },
  };
</script>

<template>
  <div
    class="frame click-to-comment"
    :class="className"
  >
    <img
      @click="click"
      @load="load"
      :src="src"
      :alt="alt"
      draggable="false"
    />
    <button
      v-for="(coordinate, index) in coordinates"
      :key="index"
      class="badge"
      :style="styleCoordinate(coordinate)"
    >
      {{index + 1}}
    </button>
  </div>
</template>
