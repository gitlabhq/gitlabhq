/* eslint-disable import/no-commonjs */
const Vue = require('vue');
const VTU = require('@vue/test-utils');
const { installCompat: installVTUCompat, fullCompatConfig } = require('vue-test-utils-compat');

function getComponentName(component) {
  if (!component) {
    return undefined;
  }

  return (
    component.name ||
    getComponentName(component.extends) ||
    component.mixins?.find((mixin) => getComponentName(mixin))
  );
}

function isLegacyExtendedComponent(component) {
  return Reflect.has(component, 'super') && component.super.extend({}).super === component.super;
}
function unwrapLegacyVueExtendComponent(selector) {
  return isLegacyExtendedComponent(selector) ? selector.options : selector;
}

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
    COMPONENT_ASYNC: 'suppress-warning',
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
  Vue.config.compilerOptions.whitespace = 'preserve';
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

  const noop = () => {};

  VTU.config.plugins.createStubs = ({ name, component: rawComponent, registerStub }) => {
    const component = unwrapLegacyVueExtendComponent(rawComponent);
    const hyphenatedName = name.replace(/\B([A-Z])/g, '-$1').toLowerCase();

    const stub = Vue.defineComponent({
      name: getComponentName(component),
      props: component.props,
      model: component.model,
      methods: Object.fromEntries(
        Object.entries(component.methods ?? {}).map(([key]) => [key, noop]),
      ),
      render() {
        const {
          $slots: slots = {},
          $scopedSlots: scopedSlots = {},
          $parent: parent,
          $vnode: vnode,
        } = this;

        const hasStaticDefaultSlot = 'default' in slots && !('default' in scopedSlots);
        const isTheOnlyChild = parent?.$.subTree === vnode;
        // this condition should be altered when https://github.com/vuejs/vue-test-utils/pull/2068 is merged
        // and our codebase will be updated to include it (@vue/test-utils@1.3.6 I assume)
        const shouldRenderAllSlots = !hasStaticDefaultSlot && isTheOnlyChild;

        const renderSlotByName = (slotName) => {
          const slot = scopedSlots[slotName] || slots[slotName];
          let result;
          if (typeof slot === 'function') {
            try {
              result = slot({});
            } catch {
              // intentionally blank
            }
          } else {
            result = slot;
          }
          return result;
        };

        const slotContents = shouldRenderAllSlots
          ? [...new Set([...Object.keys(slots), ...Object.keys(scopedSlots)])]
              .map(renderSlotByName)
              .filter(Boolean)
          : renderSlotByName('default');

        return Vue.h(`${hyphenatedName || 'anonymous'}-stub`, this.$props, slotContents);
      },
    });

    if (typeof component === 'function') {
      component()?.then?.((resolvedComponent) => {
        registerStub({ source: resolvedComponent.default, stub });
      });
    }

    return stub;
  };
}
