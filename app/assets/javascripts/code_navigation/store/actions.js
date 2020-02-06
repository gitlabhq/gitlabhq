import api from '~/api';
import { __ } from '~/locale';
import createFlash from '~/flash';
import * as types from './mutation_types';
import { getCurrentHoverElement, setCurrentHoverElement, addInteractionClass } from '../utils';

export default {
  setInitialData({ commit }, data) {
    commit(types.SET_INITIAL_DATA, data);
  },
  requestDataError({ commit }) {
    commit(types.REQUEST_DATA_ERROR);
    createFlash(__('An error occurred loading code navigation'));
  },
  fetchData({ commit, dispatch, state }) {
    commit(types.REQUEST_DATA);

    api
      .lsifData(state.projectPath, state.commitId, state.path)
      .then(({ data }) => {
        const normalizedData = data.reduce((acc, d) => {
          if (d.hover) {
            acc[`${d.start_line}:${d.start_char}`] = d;
            addInteractionClass(d);
          }
          return acc;
        }, {});

        commit(types.REQUEST_DATA_SUCCESS, normalizedData);
      })
      .catch(() => dispatch('requestDataError'));
  },
  showDefinition({ commit, state }, { target: el }) {
    let definition;
    let position;

    if (!state.data) return;

    const isCurrentElementPopoverOpen = el.classList.contains('hll');

    if (getCurrentHoverElement()) {
      getCurrentHoverElement().classList.remove('hll');
    }

    if (el.classList.contains('js-code-navigation') && !isCurrentElementPopoverOpen) {
      const { lineIndex, charIndex } = el.dataset;

      position = {
        x: el.offsetLeft,
        y: el.offsetTop,
        height: el.offsetHeight,
      };
      definition = state.data[`${lineIndex}:${charIndex}`];

      el.classList.add('hll');

      setCurrentHoverElement(el);
    }

    commit(types.SET_CURRENT_DEFINITION, { definition, position });
  },
};
