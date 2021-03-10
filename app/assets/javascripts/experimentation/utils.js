// This file only applies to use of experiments through https://gitlab.com/gitlab-org/gitlab-experiment
import { get } from 'lodash';

export function getExperimentData(experimentName) {
  return get(window, ['gon', 'experiment', experimentName]);
}

export function isExperimentVariant(experimentName, variantName) {
  return getExperimentData(experimentName)?.variant === variantName;
}
