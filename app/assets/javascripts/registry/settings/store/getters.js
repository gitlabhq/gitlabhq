import { isEqual } from 'lodash';
import { findDefaultOption } from '../../shared/utils';

export const getCadence = state =>
  state.settings.cadence || findDefaultOption(state.formOptions.cadence);

export const getKeepN = state =>
  state.settings.keep_n || findDefaultOption(state.formOptions.keepN);

export const getOlderThan = state =>
  state.settings.older_than || findDefaultOption(state.formOptions.olderThan);

export const getSettings = (state, getters) => ({
  enabled: state.settings.enabled,
  cadence: getters.getCadence,
  older_than: getters.getOlderThan,
  keep_n: getters.getKeepN,
  name_regex: state.settings.name_regex,
  name_regex_keep: state.settings.name_regex_keep,
});

export const getIsEdited = state => !isEqual(state.original, state.settings);

export const getIsDisabled = state => {
  return !(state.original || state.enableHistoricEntries);
};
