import VueCompatOriginal from '@vue/compat';
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
      config.el = new DocumentFragment();
    }
    super(config, ...rest);
    if (originalEl) {
      originalEl?.replaceWith(config.el);
    }
  }
}

GitLabPatchedVue.configureCompat(compatConfig);

export default GitLabPatchedVue;
