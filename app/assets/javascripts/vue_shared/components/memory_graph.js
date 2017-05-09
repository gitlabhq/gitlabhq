export default {
  name: 'MemoryGraph',
  props: {
    metrics: { type: Array, required: true },
    width: { type: String, required: true },
    height: { type: String, required: true },
  },
  data() {
    return {
      pathD: '',
      pathViewBox: '',
      // dotX: '',
      // dotY: '',
    };
  },
  mounted() {
    const renderData = this.$props.metrics.map(v => v[1]);
    const maxMemory = Math.max.apply(null, renderData);
    const minMemory = Math.min.apply(null, renderData);
    const diff = maxMemory - minMemory;
    // const cx = 0;
    // const cy = 0;
    const lineWidth = renderData.length;
    const linePath = renderData.map((y, x) => `${x} ${maxMemory - y}`);
    this.pathD = `M ${linePath}`;
    this.pathViewBox = `0 0 ${lineWidth} ${diff}`;
  },
  template: `
    <div class="memory-graph-container">
      <svg :width="width" :height="height" xmlns="http://www.w3.org/2000/svg">
        <path :d="pathD" :viewBox="pathViewBox" />
        <!--<circle r="0.8" :cx="dotX" :cy="dotY" tranform="translate(0 -1)" /> -->
      </svg>
    </div>
  `,
};
