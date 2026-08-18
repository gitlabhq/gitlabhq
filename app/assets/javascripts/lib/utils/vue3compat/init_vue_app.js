import Vue from 'vue';
import { logDevNotice } from '../../logger';
import { createMountWrapper, replaceWithMountWrapperContents } from './mount_wrapper';
import { toHandlerKey } from './to_handler_key';

const resolveElement = (el) => (el instanceof Element ? el : document.querySelector(el));

const toFlatListeners = (events = {}) =>
  Object.fromEntries(
    Object.entries(events).map(([event, handler]) => [toHandlerKey(event), handler]),
  );

// BootstrapVue root-bus "action" events that app code emits on `$root` to
// open/close GlModal by id (BV_SHOW_MODAL / BV_HIDE_MODAL in
// ~/lib/utils/constants, plus raw-string sites like profile/password_prompt).
const BV_ROOT_ACTION_EVENTS = ['bv::show::modal', 'bv::hide::modal', 'bv::toggle::modal'];

// Minimal per-app event bus backing the Vue-2-style `$on`/`$off`/`$once`
// surface that the native @gitlab/ui-vue3 GlModal feature-detects on the app
// root (its "@vue/compat host" branch registers the `bv::*::modal` action
// handlers via `root.$on` — see the modal port's rootBusActions). Handlers
// are snapshotted before dispatch so `$off` during emit is safe.
const createBvRootBus = () => {
  const handlers = new Map();

  const listeners = (event) => {
    if (!handlers.has(event)) {
      handlers.set(event, new Set());
    }
    return handlers.get(event);
  };

  return {
    on(event, handler) {
      listeners(event).add(handler);
    },
    off(event, handler) {
      const registered = handlers.get(event);
      if (!registered) {
        return;
      }
      registered.forEach((entry) => {
        if (entry === handler || entry.originalHandler === handler) {
          registered.delete(entry);
        }
      });
    },
    once(event, handler) {
      const wrapper = (...args) => {
        this.off(event, wrapper);
        handler(...args);
      };
      wrapper.originalHandler = handler;
      this.on(event, wrapper);
    },
    emit(event, ...args) {
      [...(handlers.get(event) || [])].forEach((handler) => handler(...args));
    },
  };
};

// Maps the root vm returned by initVueApp to the teardown of its Vue 3 app
// (`app.unmount()`), which is not reachable from the vm itself: @vue/compat
// only wires the legacy `vm.$destroy()` for `new Vue` roots, so calling it on
// a `createApp` root is inert. See unmountVueApp below.
const vue3AppTeardowns = new WeakMap();

/**
 * Mounts a component as the root of a new Vue app in a way that works under
 * both Vue 2 and Vue 3. This is the canonical replacement for app-bootstrap
 * `new Vue({ el, render })` roots (see the `vue3-init-vue-app` codemod in
 * scripts/frontend/codemods/vue3_init_vue_app.mjs):
 *
 * - On Vue 2 it is exactly `new Vue({ el, ...options, render })`, so
 *   production behavior is unchanged: the mount element is replaced by the
 *   rendered component.
 * - On Vue 3 it uses `createApp` (avoiding the deprecated global-mount API)
 *   and emulates the Vue 2 replace-mount semantics via ./mount_wrapper.js,
 *   producing the same DOM as the Vue 2 path.
 *
 * The root render is pinned with `compatConfig: { RENDER_FUNCTION: false }`
 * on Vue 3, so converted roots do not contribute to the RENDER_FUNCTION
 * deprecation census.
 *
 * @param {Object} config
 * @param {Element|string} config.el - Element (or selector) to mount on. The
 *     element is replaced by the rendered component, as with Vue 2 `el`.
 * @param {Object} config.component - The root component to render.
 * @param {Object} [config.props] - Props passed to the root component.
 *     Evaluated once at init time; app roots are mounted once with static
 *     (usually dataset-derived) props, so do not pass values that are
 *     expected to be re-read reactively.
 * @param {Object} [config.events] - Event listeners attached to the root
 *     component, as `{ 'event-name': handler }` (the Vue 2 `on:` vnode-data
 *     shape). On Vue 2 they are passed as `on`; on Vue 3 they are flattened
 *     to camelized `onEventName` props, which Vue 3's emit matches for both
 *     kebab-case and camelCase event spellings.
 * @param {string} [config.name] - Name of the app root.
 * @param {Object|Function} [config.provide] - Root `provide` option.
 * @param {Object} [config.store] - Vuex store.
 * @param {Object} [config.router] - Vue Router instance.
 * @param {Object} [config.apolloProvider] - VueApollo provider. On Vue 2 it
 *     is the classic root option (vue-apollo v3); on Vue 3 it is additionally
 *     installed with `app.use(apolloProvider)`, the @vue/apollo-option v4
 *     install path (the provider itself is the plugin).
 * @param {Object} [config.pinia] - Pinia instance.
 * @param {Array} [config.plugins] - Vue plugins the app depends on. Each
 *     entry is either a plugin or a `[plugin, ...options]` tuple (mirroring
 *     the `Vue.use(plugin, options)` signature). On Vue 2 they are installed
 *     globally (`Vue.use`, idempotent — equivalent to today's module-scope
 *     installs); on Vue 3 they are applied per-app (`app.use`), which is the
 *     endgame model for global plugin state.
 * @returns {Object|null} The root component instance. On Vue 3, `null` is
 *     returned when `el` does not resolve to an element (the Vue 2 path
 *     keeps the legacy behavior of constructing an unmounted instance).
 *     CAVEAT: on Vue 3, calling the legacy `vm.$destroy()` on the returned
 *     root is inert (@vue/compat only wires it for `new Vue` roots) — roots
 *     that callers need to tear down must be destroyed with unmountVueApp
 *     (below), passing the value returned here.
 */
export function initVueApp({
  el,
  component,
  props,
  events,
  name,
  provide,
  store,
  router,
  apolloProvider,
  pinia,
  plugins = [],
}) {
  if (Vue.version.startsWith('2')) {
    plugins.forEach((plugin) => (Array.isArray(plugin) ? Vue.use(...plugin) : Vue.use(plugin)));

    return new Vue({
      el,
      name,
      provide,
      store,
      router,
      apolloProvider,
      pinia,
      render(createElement) {
        const data = {
          ...(props !== undefined ? { props } : {}),
          ...(events !== undefined ? { on: events } : {}),
        };

        return createElement(component, Object.keys(data).length ? data : undefined);
      },
    });
  }

  const targetEl = el && resolveElement(el);
  if (!targetEl) {
    return null;
  }

  if (name) {
    logDevNotice(`[V] Using Vue.js 3 for ${name}`);
  }

  // Per-app replacement for the BootstrapVue root event bus. Plain Vue 3
  // roots have no `$on`, so `this.$root.$emit('bv::show::modal', id)` (the
  // repo-wide GlModal open/close idiom) would be unobservable:
  // - the app root declares the `bv::*::modal` action events in `emits` and
  //   forwards them (root vnode listeners, passed as root props to
  //   `createApp`) onto a per-app bus, so `$root.$emit(...)` call sites work
  //   unchanged;
  // - `$on`/`$off`/`$once` are exposed via `app.config.globalProperties`
  //   (the public-instance proxy resolves `$`-prefixed keys it does not own
  //   there), which the native @gitlab/ui-vue3 GlModal feature-detects on
  //   `$root` to register its show/hide/toggle handlers — completing the
  //   bridge with the exact per-app scoping the Vue 2 bus had.
  // The facade is app-scoped by design: it exists for `$root` bus usage, not
  // as a general per-component event emitter (no such callers remain).
  //
  // Under @vue/compat none of this is needed: INSTANCE_EVENT_EMITTER gives
  // every instance real `$on`/`$emit`, so the legacy root-bus semantics work
  // natively — and the vnode-listener hop would only produce undeclared-emit
  // warnings for the `bv::*` notification events bootstrap-vue emits on
  // `$root`.
  const isCompatRuntime = typeof Vue.configureCompat === 'function';
  const bvRootBus = isCompatRuntime ? null : createBvRootBus();
  const bvRootListeners = bvRootBus
    ? Object.fromEntries(
        BV_ROOT_ACTION_EVENTS.map((event) => [
          toHandlerKey(event),
          (...args) => bvRootBus.emit(event, ...args),
        ]),
      )
    : null;

  // NOTE on parity with the legacy `new Vue(...)` compat path: @vue/compat
  // copies the singleton app's registrations (global plugins/mixins, and the
  // `__compat__transition`-style built-in aliases that legacy Vue 2 render
  // functions resolve) into every app created with `createApp`, so apps
  // created here behave exactly like `new Vue({ el, ... })` roots do on the
  // Vue 3 lanes (see applySingletonAppMutations in @vue/compat and the
  // "legacy built-in component names" spec).
  const app = Vue.createApp(
    {
      name,
      provide,
      store,
      router,
      apolloProvider,
      pinia,
      // Declared so the root listeners above are consumed as emit targets
      // instead of falling through as attrs onto the rendered component.
      ...(bvRootBus ? { emits: BV_ROOT_ACTION_EVENTS } : {}),
      // The render below is native Vue 3 shape (zero-arg, flat props); opt out
      // of @vue/compat's legacy render-function emulation so it is not
      // misclassified as a Vue 2 render (and warned about as RENDER_FUNCTION).
      compatConfig: { RENDER_FUNCTION: false },
      render: () =>
        Vue.h(component, events !== undefined ? { ...props, ...toFlatListeners(events) } : props),
    },
    bvRootListeners,
  );

  if (bvRootBus) {
    Object.assign(app.config.globalProperties, {
      $on(event, handler) {
        bvRootBus.on(event, handler);
        return this;
      },
      $off(event, handler) {
        bvRootBus.off(event, handler);
        return this;
      },
      $once(event, handler) {
        bvRootBus.once(event, handler);
        return this;
      },
    });
  }

  // `new Vue({ pinia })` installs pinia through PiniaVuePlugin on Vue 2; on
  // plain Vue 3 the root option is inert and pinia is an app plugin. Without
  // this, `$pinia` is undefined (store helpers only work through the
  // module-scope active pinia, and every read warns during render).
  if (pinia) {
    app.use(pinia);
  }

  // @vue/apollo-option v4 install: the provider itself is the app plugin.
  // The root option above still matters — the vue-apollo compat shim
  // resolves a component's own `apolloProvider` option first (vue-apollo v3
  // parent-chain semantics), with the app-level install as the fallback.
  // Under @vue/compat the vue-apollo shim installs the provider from the
  // root option itself; the explicit install would warn as a duplicate.
  if (apolloProvider && typeof Vue.configureCompat !== 'function') {
    app.use(apolloProvider);
  }

  plugins.forEach((plugin) => (Array.isArray(plugin) ? app.use(...plugin) : app.use(plugin)));

  const wrapperEl = createMountWrapper(targetEl);
  const vm = app.mount(wrapperEl);
  replaceWithMountWrapperContents(targetEl, wrapperEl, name);

  vue3AppTeardowns.set(vm, () => app.unmount());

  return vm;
}

/**
 * Tears down an app created with initVueApp, on both runtimes. Pass the
 * value initVueApp returned, or any component instance belonging to the app
 * (some bootstraps hand out an inner instance as their public API); the app
 * is resolved through `$root`. A null handle is a no-op, matching the Vue 3
 * missing-element bootstrap result.
 *
 * - On Vue 2 this is exactly the legacy root `vm.$destroy()`: watchers and
 *   listeners are torn down and lifecycle hooks fire, but the rendered DOM
 *   is left in place — unchanged from the pre-conversion call sites, which
 *   remove the element themselves when they need to.
 * - On Vue 3 it calls `app.unmount()`, which also REMOVES the rendered DOM
 *   from the document (`createApp` semantics; the replaced mount element is
 *   not restored on either runtime). Callers that remove the root element
 *   manually for Vue 2 must null-guard the removal (e.g.
 *   `vm.$el.parentNode?.removeChild(vm.$el)`) so it is a no-op here.
 *
 * @param {Object|null} vm - A component instance of the app to tear down,
 *     typically the value returned by initVueApp.
 */
export function unmountVueApp(vm) {
  if (!vm) {
    return;
  }

  // For the value initVueApp returns, `$root` is the instance itself; for
  // inner instances handed out as a bootstrap's public API it resolves to
  // that same app root.
  const root = vm.$root || vm;

  if (Vue.version.startsWith('2')) {
    root.$destroy();
    return;
  }

  const teardown = vue3AppTeardowns.get(root);
  if (teardown) {
    // Drop the entry first so a second unmountVueApp call is a no-op instead
    // of a "app already unmounted" runtime warning ($destroy on Vue 2 is
    // idempotent, too).
    vue3AppTeardowns.delete(root);
    teardown();
  }
}
