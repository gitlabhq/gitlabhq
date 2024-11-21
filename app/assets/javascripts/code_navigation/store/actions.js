import axios from '~/lib/utils/axios_utils';
import { getCurrentHoverElement, setCurrentHoverElement, addInteractionClass } from '../utils';
import * as types from './mutation_types';

export default {
  setInitialData({ commit }, data) {
    commit(types.SET_INITIAL_DATA, data);
  },
  requestDataError({ commit }) {
    commit(types.REQUEST_DATA_ERROR);
  },
  fetchData({ commit, dispatch, state }) {
    commit(types.REQUEST_DATA);

    state.blobs.forEach(({ path, codeNavigationPath }) => {
      axios
        .get(codeNavigationPath)
        .then(({ data }) => {
          const normalizedData = data.reduce((acc, d) => {
            if (d.hover) {
              acc[`${d.start_line}:${d.start_char}`] = {
                ...d,
                definitionLineNumber: parseInt(d.definition_path?.split('#L').pop() || 0, 10),
              };
            }
            return acc;
          }, {});

          commit(types.REQUEST_DATA_SUCCESS, { path, normalizedData });
        })
        .catch(() => dispatch('requestDataError'));
    });
  },
  showBlobInteractionZones({ state }, path) {
    if (state.data && state.data[path]) {
      Object.values(state.data[path]).forEach((d) =>
        addInteractionClass({ path, d, wrapTextNodes: state.wrapTextNodes }),
      );
    }
  },
  showDefinition({ commit, state }, { target: el }) {
    let definition;
    let position;

    if (!state.data) return;

    const isCurrentElementPopoverOpen = el.classList.contains('hll');

    if (getCurrentHoverElement()) {
      getCurrentHoverElement().classList.remove('hll');
    }

    const blobEl = el.closest('[data-path]');

    if (!blobEl) {
      commit(types.SET_CURRENT_DEFINITION, { definition, position });

      return;
    }

    const blobPath = blobEl.dataset.path;
    const data = state.data[blobPath];

    if (!data) return;

    if (el.closest('.js-code-navigation') && !isCurrentElementPopoverOpen) {
      const { lineIndex, charIndex } = el.dataset;

      position = {
        x: el.offsetLeft || 0,
        y: el.offsetTop + (el.closest('pre.code')?.offsetTop || 0) || 0,
        height: el.offsetHeight,
        lineIndex: parseInt(lineIndex, 10),
      };
      definition = data[`${lineIndex}:${charIndex}`];

      el.classList.add('hll');

      setCurrentHoverElement(el);
    }

    commit(types.SET_CURRENT_DEFINITION, { definition, position, blobPath });
  },
};
