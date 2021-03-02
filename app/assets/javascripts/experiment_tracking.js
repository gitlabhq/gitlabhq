import { get } from 'lodash';
import Tracking from '~/tracking';

const TRACKING_CONTEXT_SCHEMA = 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0';

export default class ExperimentTracking {
  constructor(experimentName, trackingArgs = {}) {
    this.trackingArgs = trackingArgs;
    this.experimentData = get(window, ['gon', 'global', 'experiment', experimentName]);
  }

  event(action) {
    if (!this.experimentData) {
      return false;
    }

    return Tracking.event(document.body.dataset.page, action, {
      ...this.trackingArgs,
      context: {
        schema: TRACKING_CONTEXT_SCHEMA,
        data: this.experimentData,
      },
    });
  }
}
