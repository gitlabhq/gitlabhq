/* eslint-disable no-underscore-dangle*/
/**
 * Pipelines' Store for commits view.
 *
 * Used to store the Pipelines rendered in the commit view in the pipelines table.
 */
require('../../vue_realtime_listener');

class PipelinesStore {
  constructor() {
    this.state = {};
    this.state.pipelines = [];
  }

  storePipelines(pipelines = []) {
    this.state.pipelines = pipelines;

    return pipelines;
  }

  /**
   * Once the data is received we will start the time ago loops.
   *
   * Everytime a request is made like retry or cancel a pipeline, every 10 seconds we
   * update the time to show how long as passed.
   *
   */
  static startTimeAgoLoops() {
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

    gl.VueRealtimeListener(removeIntervals, startIntervals);
  }
}

module.exports = PipelinesStore;
