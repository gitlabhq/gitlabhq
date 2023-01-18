import Vue from 'vue';
import Vuex from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
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

  const { projectId, ref, commitsPath, refType } = el.dataset;
  const commitsPathPrefix = commitsPath.match(COMMITS_PATH_REGEX)?.[0];
  const useSymbolicRefNames = Boolean(refType);
  return new Vue({
    el,
    render(createElement) {
      return createElement(RefSelector, {
        props: {
          projectId,
          value: useSymbolicRefNames ? `refs/${refType}/${ref}` : ref,
          useSymbolicRefNames,
          refType,
        },
        on: {
          input(selected) {
            if (useSymbolicRefNames) {
              const matches = selected.match(/refs\/(heads|tags)\/(.+)/);
              if (matches) {
                visitUrl(`${commitsPathPrefix}/${matches[2]}?ref_type=${matches[1]}`);
              } else {
                visitUrl(`${commitsPathPrefix}/${selected}`);
              }
            } else {
              visitUrl(`${commitsPathPrefix}/${selected}`);
            }
          },
        },
      });
    },
  });
};
