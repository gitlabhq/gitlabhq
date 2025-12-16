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
function getStubProps(component) {
  const stubProps = { ...component.props };
  component.mixins?.forEach((mixin) => {
    Object.assign(stubProps, unwrapLegacyVueExtendComponent(mixin).props);
  });
  return stubProps;
}

if (global.document) {
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

  installVTUCompat(
    VTU,
    {
      ...fullCompatConfig,
      WRAPPER_SET_VALUE_DOES_NOT_TRIGGER_CHANGE: false,
    },
    compatH,
  );

  jest.mock('@vue/test-utils', () => {
    const actualVTU = jest.requireActual('@vue/test-utils');

    return {
      ...actualVTU,
      RouterLinkStub: {
        ...actualVTU.RouterLinkStub,
        render() {
          const { default: defaultSlot } = this.$scopedSlots ?? {};
          const defaultSlotFn =
            defaultSlot && typeof defaultSlot !== 'function' ? () => defaultSlot : defaultSlot;
          return actualVTU.RouterLinkStub.render.call({
            $slots: defaultSlot ? { default: defaultSlotFn } : undefined,
            custom: this.custom,
          });
        },
      },
    };
  });

  VTU.config.global.renderStubDefaultSlot = true;

  const noop = () => {};
  const invalidProperties = new Set();

  const getDescriptor = (root, prop) => {
    let obj = root;
    while (obj != null) {
      const desc = Object.getOwnPropertyDescriptor(obj, prop);
      if (desc) {
        return desc;
      }
      obj = Object.getPrototypeOf(obj);
    }
    return null;
  };

  const isPropertyValidOnDomNode = (prop) => {
    if (invalidProperties.has(prop)) {
      return false;
    }

    const domNode = document.createElement('anonymous-stub');
    const descriptor = getDescriptor(domNode, prop);
    if (descriptor && descriptor.get && !descriptor.set) {
      invalidProperties.add(prop);
      return false;
    }

    return true;
  };

  VTU.config.plugins.createStubs = ({ name, component: rawComponent, registerStub, stubs }) => {
    const component = unwrapLegacyVueExtendComponent(rawComponent);
    const hyphenatedName = name.replace(/\B([A-Z])/g, '-$1').toLowerCase();
    const stubTag = stubs?.[name] ? name : hyphenatedName;

    const stub = Vue.defineComponent({
      name: getComponentName(component),
      props: getStubProps(component),
      model: component.model ?? component.mixins?.find((m) => m.model),
      methods: Object.fromEntries(
        Object.entries(component.methods ?? {}).map(([key]) => [key, noop]),
      ),
      render() {
        const { $scopedSlots: scopedSlots = {} } = this;

        // eslint-disable-next-line no-underscore-dangle
        const hasDefaultSlot = 'default' in scopedSlots && scopedSlots.default._ns;
        const shouldRenderAllSlots = !component.functional && !hasDefaultSlot;

        const renderSlotByName = (slotName) => {
          const slot = scopedSlots[slotName];
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
          ? Object.keys(scopedSlots).map(renderSlotByName).filter(Boolean)
          : renderSlotByName('default');

        const props = Object.fromEntries(
          Object.entries(this.$props)
            .filter(([prop]) => isPropertyValidOnDomNode(prop))
            .map(([key, value]) => [key, typeof value === 'function' ? ['[Function]'] : value]),
        );

        return Vue.h(`${stubTag || 'anonymous'}-stub`, props, slotContents);
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
