import VueCompatOriginal from '@vue/compat';

export * from '@vue/compat';

class GitLabPatchedVue extends VueCompatOriginal {
  constructor(rawConfig, ...rest) {
    const config = rawConfig?.el ? { ...rawConfig } : rawConfig;
    let originalEl;
    if (config?.el) {
      originalEl = config.el instanceof Element ? config.el : document.querySelector(config.el);
      config.el = new DocumentFragment();
    }
    super(config, ...rest);
    if (originalEl) {
      originalEl.parentNode.replaceChild(config.el, originalEl);
    }
  }

  static use(plugin, ...options) {
    if (plugin && typeof plugin.install === 'function') {
      plugin.install(this, ...options);
    } else if (typeof plugin === 'function') {
      plugin(this, ...options);
    }
    return this;
  }
}

GitLabPatchedVue.configureCompat({
  MODE: 2,

  GLOBAL_MOUNT: 'suppress-warning',
  GLOBAL_EXTEND: 'suppress-warning',
  GLOBAL_PROTOTYPE: 'suppress-warning',
  RENDER_FUNCTION: 'suppress-warning',

  INSTANCE_DESTROY: 'suppress-warning',
  INSTANCE_DELETE: 'suppress-warning',

  INSTANCE_ATTRS_CLASS_STYLE: 'suppress-warning',
  INSTANCE_CHILDREN: 'suppress-warning',
  INSTANCE_SCOPED_SLOTS: 'suppress-warning',
  INSTANCE_LISTENERS: 'suppress-warning',
  INSTANCE_EVENT_EMITTER: 'suppress-warning',
  INSTANCE_EVENT_HOOKS: 'suppress-warning',
  INSTANCE_SET: 'suppress-warning',
  GLOBAL_OBSERVABLE: 'suppress-warning',
  GLOBAL_SET: 'suppress-warning',
  COMPONENT_FUNCTIONAL: 'suppress-warning',
  COMPONENT_V_MODEL: 'suppress-warning',
  COMPONENT_ASYNC: 'suppress-warning',
  CUSTOM_DIR: 'suppress-warning',
  OPTIONS_BEFORE_DESTROY: 'suppress-warning',
  OPTIONS_DATA_MERGE: 'suppress-warning',
  OPTIONS_DATA_FN: 'suppress-warning',
  OPTIONS_DESTROYED: 'suppress-warning',
  ATTR_FALSE_VALUE: 'suppress-warning',

  CONFIG_WHITESPACE: 'suppress-warning',
  CONFIG_OPTION_MERGE_STRATS: 'suppress-warning',
  PRIVATE_APIS: 'suppress-warning',
  WATCH_ARRAY: 'suppress-warning',
});

export default GitLabPatchedVue;
