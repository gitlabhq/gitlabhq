import Api from '~/api';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import eventHub from '../../../eventhub';
import * as types from './mutation_types';

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

export const fetchTemplateTypes = ({ dispatch, state, rootState }) => {
  if (!Object.keys(state.selectedTemplateType).length) return Promise.reject();

  dispatch('requestTemplateTypes');

  const fetchPages = (page = 1, prev = []) =>
    Api.projectTemplates(rootState.currentProjectId, state.selectedTemplateType.key, {
      page,
      per_page: 100,
    })
      .then(({ data, headers }) => {
        const nextPage = parseInt(normalizeHeaders(headers)['X-NEXT-PAGE'], 10);
        const nextData = prev.concat(data);

        dispatch('receiveTemplateTypesSuccess', nextData);

        return nextPage ? fetchPages(nextPage, nextData) : nextData;
      })
      .catch(() => dispatch('receiveTemplateTypesError'));

  return fetchPages();
};

export const setSelectedTemplateType = ({ commit, dispatch, rootGetters }, type) => {
  commit(types.SET_SELECTED_TEMPLATE_TYPE, type);

  if (rootGetters.activeFile.prevPath === type.name) {
    dispatch('discardFileChanges', rootGetters.activeFile.path, { root: true });
  } else if (rootGetters.activeFile.name !== type.name) {
    dispatch(
      'renameEntry',
      {
        path: rootGetters.activeFile.path,
        name: type.name,
      },
      { root: true },
    );
  }
};

export const receiveTemplateError = ({ dispatch }, template) => {
  dispatch(
    'setErrorMessage',
    {
      text: __('Error loading template.'),
      action: (payload) =>
        dispatch('fetchTemplateTypes', payload).then(() =>
          dispatch('setErrorMessage', null, { root: true }),
        ),
      actionText: __('Please try again'),
      actionPayload: template,
    },
    { root: true },
  );
};

export const fetchTemplate = ({ dispatch, state, rootState }, template) => {
  if (template.content) {
    return dispatch('setFileTemplate', template);
  }

  return Api.projectTemplate(
    rootState.currentProjectId,
    state.selectedTemplateType.key,
    template.key || template.name,
  )
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

  if (file.prevPath) {
    dispatch('discardFileChanges', file.path, { root: true });
  }
};
