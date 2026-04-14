import VueCompatOriginal from '@vue/compat';

import GlLicensedFeaturesPlugin from '../../../vue_shared/gl_licensed_features_plugin';
import GlFeatureFlagsPlugin from '../../../vue_shared/gl_feature_flags_plugin';
import GlAbilitiesPlugin from '../../../vue_shared/gl_abilities_plugin';
import Translate from '../../../vue_shared/translate';

import { logDevNotice } from '../../logger';
import { compatConfig } from './compat_config';

export * from '@vue/compat';

class GitLabPatchedVue extends VueCompatOriginal {
  constructor(rawConfig, ...rest) {
    if (rawConfig?.name) {
      logDevNotice(`[V] Using Vue.js 3 (with @vue/compat) for ${rawConfig.name}`);
    }

    const config = rawConfig?.el ? { ...rawConfig } : rawConfig;
    let originalEl;
    if (config?.el) {
      originalEl = config.el instanceof Element ? config.el : document.querySelector(config.el);
      config.el = document.createElement('div');
      config.el.style.display = 'contents';
      config.el.dataset.info = 'gitlab-vue3-compat-wrapper';
      // We need to have it in real HTML otherwise accessing for example attached CSS vars might fail
      originalEl.appendChild(config.el);
    }
    super(config, ...rest);
    if (originalEl) {
      const fragment = new DocumentFragment();
      fragment.replaceChildren(...config.el.childNodes);
      originalEl.replaceWith(fragment);
    }
  }
}

GitLabPatchedVue.configureCompat(compatConfig);

// This is temporary place for this
// We are basically mirroring app/assets/javascripts/commons/vue.js
// We should not put them in jest, but we don't want for now to add
// extra entrypoint in vite/webpack - so this ugly check
if (typeof jest === 'undefined') {
  GitLabPatchedVue.use(GlLicensedFeaturesPlugin);
  GitLabPatchedVue.use(GlFeatureFlagsPlugin);
  GitLabPatchedVue.use(GlAbilitiesPlugin);
  GitLabPatchedVue.use(Translate);
}

export default GitLabPatchedVue;
