import PromPusher from './prom_pusher';

const PromMetrics = {
  rightSidebar: {
    toggle() {
      PromPusher.getMetric('counter', 'toggle_sidebar', 'Counts right sidebar toggles').inc();
    },
  },
};

export default PromMetrics;
