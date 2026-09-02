import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import SmartInterval from '~/smart_interval';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import { observable } from '~/lib/utils/observable';

export const PIPELINE_STATE = {
  loading: 'LOADING',
  noPipeline: 'NO_PIPELINE',
  running: 'RUNNING',
  complete: 'COMPLETE',
};

const POLLING_SETTINGS = {
  startingInterval: secondsToMilliseconds(5),
  incrementByFactorOf: 2,
  maxInterval: secondsToMilliseconds(120),
};

// The reports tab and the tab count mount on the same page and want the same
// payload, so one store and one poller serve both.
const state = observable('mr_reports_data', { mr: null });

let interval = null;
let consumers = 0;
let started = false;

const pipelineStateOf = (mr) => {
  if (!mr) return PIPELINE_STATE.loading;
  if (!mr.pipelineIid) return PIPELINE_STATE.noPipeline;
  if (mr.isPipelineActive) return PIPELINE_STATE.running;

  return PIPELINE_STATE.complete;
};

const isComplete = () => pipelineStateOf(state.mr) === PIPELINE_STATE.complete;

const fetch = () =>
  MRWidgetService.fetchInitialData()
    .then(({ data }) => {
      const widgetData = { ...window.gl.mrWidgetData, ...data };

      if (state.mr) state.mr.setData(widgetData);
      else state.mr = new MRWidgetStore(widgetData);
    })
    .catch(() => {});

const stop = () => {
  interval?.destroy();
  interval = null;
  started = false;
};

const start = async () => {
  const { merge_request_cached_widget_path: cachedPath, merge_request_widget_path: path } =
    window.gl?.mrWidgetData || {};

  if (started || !cachedPath || !path) return;

  started = true;

  await fetch();

  // Every consumer may have gone, or another start may have begun polling,
  // while the request above was in flight.
  if (consumers === 0 || interval || isComplete()) return;

  interval = new SmartInterval({
    callback: () => fetch().then(() => isComplete() && stop()),
    ...POLLING_SETTINGS,
    immediateExecution: false,
  });
};

// Only for specs: the store and poller outlive any single component.
export const resetMergeRequestData = () => {
  stop();
  consumers = 0;
  state.mr = null;
};

export default {
  computed: {
    mr() {
      return state.mr;
    },
    pipelineState() {
      return pipelineStateOf(state.mr);
    },
  },
  created() {
    consumers += 1;

    start();
  },
  beforeDestroy() {
    // Clamped: test teardown can destroy a wrapper after the store was reset.
    consumers = Math.max(consumers - 1, 0);

    if (consumers === 0) stop();
  },
};
