import { identity } from 'lodash';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { DEFAULT_BRANCH, IDE_ELEMENT_ID } from '~/ide/constants';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '../lib/utils/common_utils';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';
import ide from './components/ide.vue';
import { createRouter } from './ide_router';
import { DEFAULT_THEME } from './lib/themes';
import { createStore } from './stores';
import { OAuthCallbackDomainMismatchErrorApp } from './oauth_callback_domain_mismatch_error';

Vue.use(Translate);

Vue.use(PerformancePlugin, {
  components: ['FileTree'],
});

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
export const initLegacyWebIDE = (el, options = {}) => {
  if (!el) return null;

  const { rootComponent = ide, extendStore = identity } = options;

  const store = createStore();
  const project = JSON.parse(el.dataset.project);
  store.dispatch('setProject', { project });

  // fire and forget fetching non-critical project info
  store.dispatch('fetchProjectPermissions');

  const router = createRouter(store, el.dataset.defaultBranch || DEFAULT_BRANCH);

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
        switchEditorSvgPath: el.dataset.switchEditorSvgPath,
      });
      this.setLinks({
        webIDEHelpPagePath: el.dataset.webIdeHelpPagePath,
        newWebIDEHelpPagePath: el.dataset.newWebIdeHelpPagePath,
        forkInfo: el.dataset.forkInfo ? JSON.parse(el.dataset.forkInfo) : null,
      });
      this.init({
        renderWhitespaceInCode: parseBoolean(el.dataset.renderWhitespaceInCode),
        editorTheme: window.gon?.user_color_scheme || DEFAULT_THEME,
        previewMarkdownPath: el.dataset.previewMarkdownPath,
        userPreferencesPath: el.dataset.userPreferencesPath,
      });
    },
    beforeDestroy() {
      // This helps tests do Singleton cleanups which we don't really have responsibility to know about here.
      this.$emit('destroy');
    },
    methods: {
      ...mapActions(['setEmptyStateSvgs', 'setLinks', 'init']),
    },
    render(createElement) {
      return createElement(rootComponent);
    },
  });
};

/**
 * Start the IDE.
 *
 * @param {Objects} options - Extra options for the IDE (Used by EE).
 */
export async function startIde(options) {
  const ideElement = document.getElementById(IDE_ELEMENT_ID);

  if (!ideElement) {
    return;
  }

  const oAuthCallbackDomainMismatchApp = new OAuthCallbackDomainMismatchErrorApp(
    ideElement,
    ideElement.dataset.callbackUrls,
  );

  if (oAuthCallbackDomainMismatchApp.isVisitingFromNonRegisteredOrigin()) {
    oAuthCallbackDomainMismatchApp.renderError();
    return;
  }

  const useNewWebIde = parseBoolean(ideElement.dataset.useNewWebIde);

  if (useNewWebIde) {
    const { initGitlabWebIDE } = await import('./init_gitlab_web_ide');
    initGitlabWebIDE(ideElement);
  } else {
    resetServiceWorkersPublicPath();
    initLegacyWebIDE(ideElement, options);
  }
}
