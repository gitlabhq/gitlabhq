import Tracking from '~/tracking';
import { TRACKING_CONTEXT_SCHEMA } from './constants';
import { getExperimentData } from './utils';

export default class ExperimentTracking {
  constructor(experimentName, trackingArgs = {}) {
    this.trackingArgs = trackingArgs;
    this.data = getExperimentData(experimentName);
  }

  event(action) {
    if (!this.data) {
      return false;
    }

    return Tracking.event(document.body.dataset.page, action, {
      ...this.trackingArgs,
      context: {
        schema: TRACKING_CONTEXT_SCHEMA,
        data: this.data,
      },
    });
  }
}
