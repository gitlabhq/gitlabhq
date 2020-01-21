import Vue from 'vue';
import { mapActions } from 'vuex';
import _ from 'underscore';
import Translate from '~/vue_shared/translate';
import ide from './components/ide.vue';
import store from './stores';
import router from './ide_router';
import { parseBoolean } from '../lib/utils/common_utils';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';

Vue.use(Translate);

/**
 * Function that receives the default store and returns an extended one.
 * @callback extendStoreCallback
 * @param {Vuex.Store} store
 * @param {Element} el
 */

/**
 * Initialize the IDE on the given element.
 *
 * @param {Element} el - The element that will contain the IDE.
 * @param {Object} options - Extra options for the IDE (Used by EE).
 * @param {Component} options.rootComponent -
 *   Component that overrides the root component.
 * @param {extendStoreCallback} options.extendStore -
 *   Function that receives the default store and returns an extended one.
 */
export function initIde(el, options = {}) {
  if (!el) return null;

  const { rootComponent = ide, extendStore = _.identity } = options;

  return new Vue({
    el,
    store: extendStore(store, el),
    router,
    created() {
      this.setEmptyStateSvgs({
        emptyStateSvgPath: el.dataset.emptyStateSvgPath,
        noChangesStateSvgPath: el.dataset.noChangesStateSvgPath,
        committedStateSvgPath: el.dataset.committedStateSvgPath,
        pipelinesEmptyStateSvgPath: el.dataset.pipelinesEmptyStateSvgPath,
        promotionSvgPath: el.dataset.promotionSvgPath,
      });
      this.setLinks({
        ciHelpPagePath: el.dataset.ciHelpPagePath,
        webIDEHelpPagePath: el.dataset.webIdeHelpPagePath,
      });
      this.setInitialData({
        clientsidePreviewEnabled: parseBoolean(el.dataset.clientsidePreviewEnabled),
        renderWhitespaceInCode: parseBoolean(el.dataset.renderWhitespaceInCode),
      });
    },
    methods: {
      ...mapActions(['setEmptyStateSvgs', 'setLinks', 'setInitialData']),
    },
    render(createElement) {
      return createElement(rootComponent);
    },
  });
}

/**
 * Start the IDE.
 *
 * @param {Objects} options - Extra options for the IDE (Used by EE).
 */
export function startIde(options) {
  document.addEventListener('DOMContentLoaded', () => {
    const ideElement = document.getElementById('ide');
    if (ideElement) {
      resetServiceWorkersPublicPath();
      initIde(ideElement, options);
    }
  });
}
