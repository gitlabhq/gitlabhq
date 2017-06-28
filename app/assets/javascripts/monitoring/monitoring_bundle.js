import PrometheusGraph from './prometheus_graph';

document.addEventListener('DOMContentLoaded', function onLoad() {
  document.removeEventListener('DOMContentLoaded', onLoad, false);
  return new PrometheusGraph();
}, false);
