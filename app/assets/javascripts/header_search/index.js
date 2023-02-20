import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import Translate from '~/vue_shared/translate';
import HeaderSearchApp from './components/app.vue';
import createStore from './store';
import { SEARCH_INPUT_FIELD_MAX_WIDTH } from './constants';

Vue.use(Translate);

export const initHeaderSearchApp = (search = '') => {
  const el = document.getElementById('js-header-search');
  const headerEl = document.querySelector('.header-content');

  if (!el && !headerEl) {
    return false;
  }

  const searchContainer = headerEl.querySelector('.global-search-container');
  const newHeader = headerEl.querySelector('.header-search-new');

  const { searchPath, issuesPath, mrPath, autocompletePath } = el.dataset;
  let { searchContext } = el.dataset;

  try {
    searchContext = JSON.parse(searchContext);
    newHeader.style.maxWidth = SEARCH_INPUT_FIELD_MAX_WIDTH;
  } catch (error) {
    Sentry.captureException(error);
  }

  return new Vue({
    el,
    store: createStore({ searchPath, issuesPath, mrPath, autocompletePath, searchContext, search }),
    render(createElement) {
      return createElement(HeaderSearchApp, {
        on: {
          expandSearchBar: () => {
            searchContainer.style.flexGrow = '1';
          },
          collapseSearchBar: () => {
            searchContainer.style.flexGrow = '0';
          },
        },
      });
    },
  });
};
