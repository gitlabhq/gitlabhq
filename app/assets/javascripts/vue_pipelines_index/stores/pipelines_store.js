/* eslint-disable no-underscore-dangle*/
import VueRealtimeListener from '../../vue_realtime_listener';

export default class PipelinesStore {
  constructor() {
    this.state = {};

    this.state.pipelines = [];
    this.state.count = {};
    this.state.pageInfo = {};
  }

  storePipelines(pipelines = []) {
    this.state.pipelines = pipelines;
  }

  storeCount(count = {}) {
    this.state.count = count;
  }

  storePagination(pagination = {}) {
    let paginationInfo;

    if (Object.keys(pagination).length) {
      const normalizedHeaders = gl.utils.normalizeHeaders(pagination);
      paginationInfo = gl.utils.parseIntPagination(normalizedHeaders);
    } else {
      paginationInfo = pagination;
    }

    this.state.pageInfo = paginationInfo;
  }

  /**
   * FIXME: Move this inside the component.
   *
   * Once the data is received we will start the time ago loops.
   *
   * Everytime a request is made like retry or cancel a pipeline, every 10 seconds we
   * update the time to show how long as passed.
   *
   */
  startTimeAgoLoops() {
    const startTimeLoops = () => {
      this.timeLoopInterval = setInterval(() => {
        this.$children[0].$children.reduce((acc, component) => {
          const timeAgoComponent = component.$children.filter(el => el.$options._componentTag === 'time-ago')[0];
          acc.push(timeAgoComponent);
          return acc;
        }, []).forEach(e => e.changeTime());
      }, 10000);
    };

    startTimeLoops();

    const removeIntervals = () => clearInterval(this.timeLoopInterval);
    const startIntervals = () => startTimeLoops();

    VueRealtimeListener(removeIntervals, startIntervals);
  }
}
