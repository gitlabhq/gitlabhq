import Vue from 'vue';
import { IDE_ELEMENT_ID } from '~/ide/constants';
import PerformancePlugin from '~/performance/vue_performance_plugin';
import Translate from '~/vue_shared/translate';
import { parseBoolean } from '../lib/utils/common_utils';
import { resetServiceWorkersPublicPath } from '../lib/utils/webpack';
import { OAuthCallbackDomainMismatchErrorApp } from './oauth_callback_domain_mismatch_error';

Vue.use(Translate);

Vue.use(PerformancePlugin, {
  components: ['FileTree'],
});

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

  const useNewWebIde = parseBoolean(ideElement.dataset.useNewWebIde);

  if (!useNewWebIde) {
    resetServiceWorkersPublicPath();
    const { initLegacyWebIDE } = await import('./init_legacy_web_ide');
    initLegacyWebIDE(ideElement, options);
    return;
  }

  const oAuthCallbackDomainMismatchApp = new OAuthCallbackDomainMismatchErrorApp(ideElement);

  if (oAuthCallbackDomainMismatchApp.shouldRenderError()) {
    oAuthCallbackDomainMismatchApp.renderError();
    return;
  }
  const { initGitlabWebIDE } = await import('./init_gitlab_web_ide');
  initGitlabWebIDE(ideElement);
}
