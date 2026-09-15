import Vue from 'vue';

/**
 * RouterViewWithSlot provides v-slot support on <router-view> for Vue Router 3
 * (used under Vue 2). Vue Router 3 lacks this API natively. Vue Router 4 (used
 * under Vue 3) provides it, and this component passes through to that native
 * implementation.
 *
 * To retire this file once Vue 2 support ends, follow this checklist:
 *
 * 1. Find all consumers: e.g. grep -rl "router_view_with_slot" app/ ee/ jh/
 *
 * 2. In each consumer's template, rename the tag from <router-view-with-slot>
 *    to <router-view>. Keep all attributes and slot content unchanged.
 *    Example:
 *
 *    Before:
 *      <router-view-with-slot #default="{ Component }">
 *        <component :is="Component" @some-event="handler">
 *          <template #some-slot>...</template>
 *        </component>
 *      </router-view-with-slot>
 *
 *    After:
 *      <router-view #default="{ Component }">
 *        <component :is="Component" @some-event="handler">
 *          <template #some-slot>...</template>
 *        </component>
 *      </router-view>
 *
 * 3. Remove the RouterViewWithSlot import and its components registration
 *    entry from each consumer's script block.
 *
 * 4. Delete this file and
 *    spec/frontend/vue_shared/spa/components/router_view_with_slot_spec.js.
 *
 * No behavior changes occur. The Vue 3 implementation is already the plain
 * passthrough described above.
 */
const isVue2 = Vue.version.startsWith('2');

function resolveConfigProps(route, config) {
  switch (typeof config) {
    case 'object':
      return config;
    case 'function':
      return config(route);
    case 'boolean':
      return config ? route.params : undefined;
    default:
      return undefined;
  }
}

// Vendored copy of Vue Router 3's real `View` component
// (https://github.com/vuejs/vue-router/blob/v3.6.5/src/components/view.js).
//
// Two additions on top of the vendored original, both backporting Vue Router
// 4's `v-slot="{ Component, route }"` API (Vue Router 3 has no equivalent):
// - When a scoped default slot is given, call it with `{ Component, route }`
//   instead of auto-rendering. This lets callers bind listeners and slots on
//   the routed component itself, not on `<router-view>` (neither router
//   forwards those through it).
// - Merge the route's configured `props` into that `Component`, same as Vue
//   Router 4 does natively. See the wrapper below for why Vue 2 needs its own
//   mechanism for this.
/* eslint-disable no-underscore-dangle -- vendored Vue Router 3 internals */
const Vue2View = {
  name: 'RouterViewWithSlot',
  functional: true,
  props: {
    name: {
      type: String,
      default: 'default',
    },
  },
  render(_, context) {
    const { children, parent, data } = context;
    const { name } = context.props;

    data.routerView = true;

    const h = parent.$createElement;
    const route = parent.$route;
    const cache = parent._routerViewCache || (parent._routerViewCache = {});

    let depth = 0;
    let inactive = false;
    let p = parent;
    while (p && p._routerRoot !== p) {
      const vnodeData = p.$vnode ? p.$vnode.data : {};
      if (vnodeData.routerView) {
        depth += 1;
      }
      if (vnodeData.keepAlive && p._directInactive && p._inactive) {
        inactive = true;
      }
      p = p.$parent;
    }
    data.routerViewDepth = depth;

    if (inactive) {
      const cachedData = cache[name];
      const cachedComponent = cachedData && cachedData.component;
      if (cachedComponent) {
        const propsToPass =
          cachedData.configProps && resolveConfigProps(cachedData.route, cachedData.configProps);
        if (propsToPass) {
          data.props = { ...data.props, ...propsToPass };
        }
        return h(cachedComponent, data, children);
      }
      return h();
    }

    const matched = route.matched[depth];
    const component = matched && matched.components[name];

    if (!matched || !component) {
      cache[name] = null;
      return h();
    }

    cache[name] = { component };

    const configProps = matched.props && matched.props[name];
    const routeProps = configProps ? resolveConfigProps(route, configProps) : undefined;
    if (configProps) {
      cache[name] = { ...cache[name], route, configProps };
    }

    // Vue Router 4's real v-slot hands the slot a vnode with `routeProps`
    // already merged in, so the caller's own `<component :is="Component">`
    // bindings layer on top of them (Vue 3 clones an existing vnode via `:is`).
    // Vue 2 has no such mechanism: a non-string `:is` value must be a
    // component definition, not a vnode. `ComponentWithRouteProps` is a
    // functional-component stand-in for that vnode instead.
    const scopedSlot = context.scopedSlots && context.scopedSlots.default;
    if (scopedSlot) {
      const ComponentWithRouteProps = {
        functional: true,
        render(createElement, wrapperContext) {
          // A dynamic `:is` binding can't be resolved to a prop at compile
          // time, so Vue 2 puts caller-bound values meant as props in
          // `data.attrs`, not `data.props`. Merge both, so either form
          // overrides `routeProps`.
          const props = {
            ...routeProps,
            ...wrapperContext.data.attrs,
            ...wrapperContext.data.props,
          };
          return createElement(
            component,
            { ...wrapperContext.data, props },
            wrapperContext.children,
          );
        },
      };
      return scopedSlot({ Component: routeProps ? ComponentWithRouteProps : component, route });
    }

    data.registerRouteInstance = (vm, val) => {
      const current = matched.instances[name];
      if ((val && current !== vm) || (!val && current === vm)) {
        matched.instances[name] = val;
      }
    };

    (data.hook || (data.hook = {})).prepatch = (_oldVnode, vnode) => {
      matched.instances[name] = vnode.componentInstance;
    };

    data.hook.init = (vnode) => {
      if (
        vnode.data.keepAlive &&
        vnode.componentInstance &&
        vnode.componentInstance !== matched.instances[name]
      ) {
        matched.instances[name] = vnode.componentInstance;
      }
    };

    if (routeProps) {
      data.props = { ...data.props, ...routeProps };
    }

    return h(component, data, children);
  },
};
/* eslint-enable no-underscore-dangle */

// Vue Router 4's own <router-view> already supports `v-slot="{ Component, route
// }"` natively, so this just forwards straight through unchanged.
const Vue3View = {
  name: 'RouterViewWithSlot',
  render() {
    return this.$createElement('router-view', { attrs: this.$attrs }, this.$scopedSlots);
  },
};

export default isVue2 ? Vue2View : Vue3View;
