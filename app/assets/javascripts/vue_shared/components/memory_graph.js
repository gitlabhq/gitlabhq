export default {
  name: 'MemoryGraph',
  props: {
    metrics: { type: Array, required: true, default: [] },
    width: { type: Number, required: true },
    height: { type: Number, required: true },
  },
  mounted() {
    const renderData = this.$props.metrics.map(v => v[1]);
    const maxMemory = Math.max.apply(null, renderData);
    const minMemory = Math.min.apply(null, renderData);
    const diff = maxMemory - minMemory;

    const svgEl = this.$el.querySelector('svg');
    const pathEl = svgEl.querySelector('path');
    const lineWidth = renderData.length;
    const linePath = renderData.map((y, x) => `${x} ${maxMemory - y}`);
    pathEl.setAttribute('d', `M ${linePath}`);
    svgEl.setAttribute('viewBox', `0 0 ${lineWidth} ${diff}`);
  },
  template: `
    <div class="memory-graph-container">
      <svg :width="width" :height="height" xmlns="http://www.w3.org/2000/svg">
        <path />
      </svg>
    </div>
  `,
};
