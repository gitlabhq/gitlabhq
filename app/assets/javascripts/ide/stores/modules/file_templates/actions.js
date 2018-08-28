import Api from '~/api';
import { __ } from '~/locale';
import * as types from './mutation_types';
import eventHub from '../../../eventhub';

export const requestTemplateTypes = ({ commit }) => commit(types.REQUEST_TEMPLATE_TYPES);
export const receiveTemplateTypesError = ({ commit, dispatch }) => {
  commit(types.RECEIVE_TEMPLATE_TYPES_ERROR);
  dispatch(
    'setErrorMessage',
    {
      text: __('Error loading template types.'),
      action: () =>
        dispatch('fetchTemplateTypes').then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
    },
    { root: true },
  );
};
export const receiveTemplateTypesSuccess = ({ commit }, templates) =>
  commit(types.RECEIVE_TEMPLATE_TYPES_SUCCESS, templates);

export const fetchTemplateTypes = ({ dispatch, state }) => {
  if (!Object.keys(state.selectedTemplateType).length) return Promise.reject();

  dispatch('requestTemplateTypes');

  return Api.templates(state.selectedTemplateType.key)
    .then(({ data }) => dispatch('receiveTemplateTypesSuccess', data))
    .catch(() => dispatch('receiveTemplateTypesError'));
};

export const setSelectedTemplateType = ({ commit }, type) =>
  commit(types.SET_SELECTED_TEMPLATE_TYPE, type);

export const receiveTemplateError = ({ dispatch }, template) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('Error loading template.'),
      action: payload =>
        dispatch('fetchTemplateTypes', payload).then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
      actionPayload: template,
    },
    { root: true },
  );
};

export const fetchTemplate = ({ dispatch, state }, template) => {
  if (template.content) {
    return dispatch('setFileTemplate', template);
  }

  return Api.templates(`${state.selectedTemplateType.key}/${template.key || template.name}`)
    .then(({ data }) => {
      dispatch('setFileTemplate', data);
    })
    .catch(() => dispatch('receiveTemplateError', template));
};

export const setFileTemplate = ({ dispatch, commit, rootGetters }, template) => {
  dispatch(
    'changeFileContent',
    { path: rootGetters.activeFile.path, content: template.content },
    { root: true },
  );
  commit(types.SET_UPDATE_SUCCESS, true);
  eventHub.$emit(`editor.update.model.new.content.${rootGetters.activeFile.key}`, template.content);
};

export const undoFileTemplate = ({ dispatch, commit, rootGetters }) => {
  const file = rootGetters.activeFile;

  dispatch('changeFileContent', { path: file.path, content: file.raw }, { root: true });
  commit(types.SET_UPDATE_SUCCESS, false);

  eventHub.$emit(`editor.update.model.new.content.${file.key}`, file.raw);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
