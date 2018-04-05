<script>
export default {
  mounted() {
    const upstreamPerformanceBar = document
      .getElementById('peek-view-performance-bar')
      .cloneNode(true);

    upstreamPerformanceBar.classList.remove('hidden');

    this.$refs.wrapper.appendChild(upstreamPerformanceBar);
  },
};
</script>
<template>
  <div
    id="peek-view-performance-bar-vue"
    class="view"
    ref="wrapper"
  ></div>
</template>
