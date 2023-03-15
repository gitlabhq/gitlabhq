/* eslint-disable import/no-commonjs */
const Vue = require('vue');
const VTU = require('@vue/test-utils');
const { installCompat: installVTUCompat, fullCompatConfig } = require('vue-test-utils-compat');

if (global.document) {
  const compatConfig = {
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
    CUSTOM_DIR: 'suppress-warning',
    OPTIONS_BEFORE_DESTROY: 'suppress-warning',
    OPTIONS_DATA_MERGE: 'suppress-warning',
    OPTIONS_DATA_FN: 'suppress-warning',
    OPTIONS_DESTROYED: 'suppress-warning',
    ATTR_FALSE_VALUE: 'suppress-warning',

    COMPILER_V_ON_NATIVE: 'suppress-warning',
    COMPILER_V_BIND_OBJECT_ORDER: 'suppress-warning',

    CONFIG_WHITESPACE: 'suppress-warning',
    CONFIG_OPTION_MERGE_STRATS: 'suppress-warning',
    PRIVATE_APIS: 'suppress-warning',
    WATCH_ARRAY: 'suppress-warning',
  };

  let compatH;
  Vue.config.compilerOptions.whitespace = 'condense';
  Vue.createApp({
    compatConfig: {
      MODE: 3,
      RENDER_FUNCTION: 'suppress-warning',
    },
    render(h) {
      compatH = h;
    },
  }).mount(document.createElement('div'));

  Vue.configureCompat(compatConfig);
  installVTUCompat(VTU, fullCompatConfig, compatH);
  VTU.config.global.renderStubDefaultSlot = true;
}
