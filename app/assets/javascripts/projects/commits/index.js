import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { encodeSaferUrl, joinPaths, visitUrl } from '~/lib/utils/url_utility';
import RefSelector from '~/ref/components/ref_selector.vue';
import AuthorSelectApp from './components/author_select.vue';
import store from './store';

Vue.use(Vuex);

export const mountCommits = (el) => {
  if (!el) {
    return null;
  }

  store.dispatch('setInitialData', el.dataset);

  return new Vue({
    el,
    store,
    render(h) {
      return h(AuthorSelectApp, {
        props: {
          projectCommitsEl: document.querySelector('.js-project-commits-show'),
        },
      });
    },
  });
};

export const initCommitsRefSwitcher = () => {
  const el = document.getElementById('js-project-commits-ref-switcher');
  const COMMITS_PATH_REGEX = /^(.*?)\/-\/commits/g;

  if (!el) return false;

  const { projectId, ref, commitsPath, refType, treePath } = el.dataset;
  const commitsPathPrefix = commitsPath.match(COMMITS_PATH_REGEX)?.[0];

  const generateRefDestinationUrl = (selectedRef, selectedRefType) => {
    const selectedRefURI = selectedRef ? encodeURIComponent(selectedRef) : '';
    const selectedTreePath = treePath ? encodeSaferUrl(treePath) : ''; // Do not escape '/'.
    const commitsPathSuffix = selectedRefType ? `?ref_type=${selectedRefType}` : '';
    return joinPaths(commitsPathPrefix, selectedRefURI, selectedTreePath) + commitsPathSuffix;
  };
  const useSymbolicRefNames = Boolean(refType);
  return new Vue({
    el,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          queryParams: { sort: 'updated_desc' },
          value: useSymbolicRefNames ? `refs/${refType}/${ref}` : ref,
          useSymbolicRefNames,
        },
        on: {
          input(selected) {
            const matches = selected.match(/refs\/(heads|tags)\/(.+)/);
            if (useSymbolicRefNames && matches) {
              visitUrl(generateRefDestinationUrl(matches[2], matches[1]));
            } else {
              visitUrl(generateRefDestinationUrl(selected));
            }
          },
        },
      });
    },
  });
};
