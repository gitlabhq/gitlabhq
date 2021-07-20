import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getExperimentData } from '~/experimentation/utils';
import { setCookie, getCookie } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import { EXPERIMENT_NAME } from './constants';

export function getExperimentSettings() {
  return JSON.parse(getCookie(EXPERIMENT_NAME) || '{}');
}

export function setExperimentSettings(settings) {
  setCookie(EXPERIMENT_NAME, settings);
}

export function isWalkthroughEnabled() {
  return getParameterByName(EXPERIMENT_NAME);
}

export function track(action) {
  const { data } = getExperimentSettings();

  if (data) {
    Tracking.event(EXPERIMENT_NAME, action, {
      context: {
        schema: TRACKING_CONTEXT_SCHEMA,
        data,
      },
    });
  }
}

export function startCodeQualityWalkthrough() {
  const data = getExperimentData(EXPERIMENT_NAME);

  if (data) {
    setExperimentSettings({ data });
  }
}
