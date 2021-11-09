// This file only applies to use of experiments through https://gitlab.com/gitlab-org/gitlab-experiment
import { get } from 'lodash';
import { DEFAULT_VARIANT, CANDIDATE_VARIANT, TRACKING_CONTEXT_SCHEMA } from './constants';

function getExperimentsData() {
  return get(window, ['gon', 'experiment'], {});
}

function convertExperimentDataToExperimentContext(experimentData) {
  return { schema: TRACKING_CONTEXT_SCHEMA, data: experimentData };
}

export function getExperimentData(experimentName) {
  return getExperimentsData()[experimentName];
}

export function getAllExperimentContexts() {
  return Object.values(getExperimentsData()).map(convertExperimentDataToExperimentContext);
}

export function isExperimentVariant(experimentName, variantName) {
  return getExperimentData(experimentName)?.variant === variantName;
}

export function getExperimentVariant(experimentName) {
  return getExperimentData(experimentName)?.variant || DEFAULT_VARIANT;
}

export function experiment(experimentName, { use, control, candidate, ...variants }) {
  const variant = getExperimentVariant(experimentName);

  switch (variant) {
    case DEFAULT_VARIANT:
      return (use || control).call();
    case CANDIDATE_VARIANT:
      return (variants.try || candidate).call();
    default:
      return variants[variant].call();
  }
}
