export default {
  name: 'MemoryGraph',
  props: {
    metrics: { type: Array, required: true },
    width: { type: Number, required: true },
    height: { type: Number, required: true },
  },
  mounted() {
    const renderData = this.$props.metrics.map(v => v[1]);
    const maxMemory = Math.max.apply(null, renderData);
    const minMemory = Math.min.apply(null, renderData);
    const diff = maxMemory - minMemory;
    const cx = 0;
    const cy = 0;

    const svgEl = this.$el.querySelector('svg');
    const pathEl = svgEl.querySelector('path');
    const circleEl = svgEl.querySelector('circle');
    const lineWidth = renderData.length;
    const linePath = renderData.map((y, x) => `${x} ${maxMemory - y}`);
    pathEl.setAttribute('d', `M ${linePath}`);
    circleEl.setAttribute('cx', cx);
    circleEl.setAttribute('cy', cy);
    svgEl.setAttribute('viewBox', `0 0 ${lineWidth} ${diff}`);
  },
  template: `
    <div class="memory-graph-container">
      <svg :width="width" :height="height" xmlns="http://www.w3.org/2000/svg">
        <path />
        <circle r="0.8" tranform="translate(0 -1)" />
      </svg>
    </div>
  `,
};
