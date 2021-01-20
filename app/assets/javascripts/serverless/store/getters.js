import { translate } from '../utils';

export const hasPrometheusMissingData = (state) => state.hasPrometheus && !state.hasPrometheusData;

// Convert the function list into a k/v grouping based on the environment scope

export const getFunctions = (state) => translate(state.functions);
