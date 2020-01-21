import { findDefaultOption } from '../utils';

export const getCadence = state =>
  state.settings.cadence || findDefaultOption(state.formOptions.cadence);
export const getKeepN = state =>
  state.settings.keep_n || findDefaultOption(state.formOptions.keepN);
export const getOlderThan = state =>
  state.settings.older_than || findDefaultOption(state.formOptions.olderThan);
