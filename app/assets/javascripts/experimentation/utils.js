// This file only applies to use of experiments through https://gitlab.com/gitlab-org/gitlab-experiment
import { get } from 'lodash';
import { DEFAULT_VARIANT, CANDIDATE_VARIANT, TRACKING_CONTEXT_SCHEMA } from './constants';

export function getExperimentData(experimentName) {
  return get(window, ['gon', 'experiment', experimentName]);
}

export function getExperimentContexts(...experimentNames) {
  return experimentNames
    .map((name) => {
      const data = getExperimentData(name);
      return data && { schema: TRACKING_CONTEXT_SCHEMA, data };
    })
    .filter((context) => context);
}

export function isExperimentVariant(experimentName, variantName) {
  return getExperimentData(experimentName)?.variant === variantName;
}

export function getExperimentVariant(experimentName) {
  return getExperimentData(experimentName)?.variant || DEFAULT_VARIANT;
}

export function experiment(experimentName, variants) {
  const variant = getExperimentVariant(experimentName);

  switch (variant) {
    case DEFAULT_VARIANT:
      return variants.use.call();
    case CANDIDATE_VARIANT:
      return variants.try.call();
    default:
      return variants[variant].call();
  }
}
