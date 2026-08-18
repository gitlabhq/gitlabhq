import Vue, { computed } from 'vue';
import {
  createRouter,
  createMemoryHistory,
  createWebHistory,
  createWebHashHistory,
  START_LOCATION,
} from '@gitlab/vue-router-vue3';
import { transformRoutes, normalizeLocation } from './vue_router_helper';

const mode = (value, options) => {
  if (!value) return null;
  let history;
  // eslint-disable-next-line default-case
  switch (value) {
    case 'history':
      history = createWebHistory(options.base);
      break;
    case 'hash':
      history = createWebHashHistory();
      break;
    case 'abstract':
      history = createMemoryHistory();
      break;
  }

  return { mode: undefined, history };
};

const base = () => ({ base: undefined });

const routes = (value) => {
  return {
    routes: transformRoutes(value),
  };
};

const scrollBehavior = (value) => {
  return {
    scrollBehavior(...args) {
      const { x, y, left, top } = value(...args);
      return { left: x || left, top: y || top };
    },
  };
};

const transformers = {
  mode,
  base,
  routes,
  scrollBehavior,
};

const transformOptions = (rawOptions = {}) => {
  const options = {
    // hash is default value in Vue Router 3
    mode: 'hash',
    ...rawOptions,
  };

  const defaultConfig = {
    // routes are mandatory in Vue Router 4
    routes: [
      {
        path: '/',
        component: {
          render() {
            return '';
          },
        },
      },
    ],
  };

  return Object.keys(options).reduce((acc, key) => {
    const value = options[key];
    if (key in transformers) {
      Object.assign(acc, transformers[key](value, options));
    } else {
      acc[key] = value;
    }
    return acc;
  }, defaultConfig);
};

const installed = new WeakMap();

export const getMatchedComponents = (instance, path) => {
  if (instance.getMatchedComponents) {
    return instance.getMatchedComponents(path);
  }

  const route = path ? instance.resolve(path) : instance.currentRoute.value;

  return route.matched.flatMap((record) => Object.values(record.components));
};

const runBeforeEnterGuards = (resolved) => {
  for (const match of resolved.matched) {
    const { beforeEnter } = match;
    if (typeof beforeEnter === 'function') {
      let redirectTarget = null;
      beforeEnter(resolved, { path: '/' }, (target) => {
        if (target && (typeof target === 'object' || typeof target === 'string')) {
          redirectTarget = target;
        }
      });
      if (redirectTarget) return redirectTarget;
    }
  }
  return null;
};

// Inverse of Vue Router 4's internal isRouteComponent(): a plain function
// without component markers is a lazy loader (`() => import(...)`).
const isLazyRouteComponent = (component) =>
  typeof component === 'function' &&
  !('displayName' in component) &&
  !('props' in component) &&
  !('__vccOpts' in component);

const hasLazyMatchedComponents = (resolved) =>
  resolved.matched.some((record) =>
    Object.values(record.components ?? {}).some(isLazyRouteComponent),
  );

// Strip trailing slash from path (except for root '/'), handling query strings and hashes
const stripTrailingSlash = (fullPath) => {
  const queryIndex = fullPath.indexOf('?');
  const hashIndex = fullPath.indexOf('#');
  let pathEnd = fullPath.length;

  if (queryIndex !== -1) pathEnd = queryIndex;
  else if (hashIndex !== -1) pathEnd = hashIndex;

  const path = fullPath.slice(0, pathEnd);
  const rest = fullPath.slice(pathEnd);

  if (path.length > 1 && path.endsWith('/')) {
    return path.slice(0, -1) + rest;
  }
  return fullPath;
};

export default class VueRouterCompat {
  constructor(options) {
    const router = createRouter(transformOptions(options));

    // Pre-committing the initial route below turns the follow-up
    // `router.replace()` into a "duplicated navigation": Vue Router 4 still
    // fires `afterEach` but skips the guard pipeline, so global `beforeEach`
    // guards would never run for the initial route (Vue Router 3 ran them).
    // A real forced navigation is no fix — it rewrites the browser URL to the
    // router's own base + path. Instead, queue the registered guards and run
    // them manually once. Stays `null` unless the pre-commit path runs.
    let pendingInitialGuards = null;

    const registerBeforeEach = router.beforeEach;
    router.beforeEach = (guard) => {
      pendingInitialGuards?.push(guard);
      const removeGuard = registerBeforeEach(guard);
      return () => {
        if (pendingInitialGuards) {
          const index = pendingInitialGuards.indexOf(guard);
          if (index !== -1) {
            pendingInitialGuards.splice(index, 1);
          }
        }
        return removeGuard();
      };
    };

    // Patch history to strip trailing slashes (mimic Vue Router 3 behavior)
    const { history } = router.options;
    const originalPush = history.push.bind(history);
    const originalReplace = history.replace.bind(history);

    history.push = (to, ...args) => {
      const normalizedTo = typeof to === 'string' ? stripTrailingSlash(to) : to;
      return originalPush(normalizedTo, ...args);
    };

    history.replace = (to, ...args) => {
      const normalizedTo = typeof to === 'string' ? stripTrailingSlash(to) : to;
      return originalReplace(normalizedTo, ...args);
    };

    // Synchronously resolve initial route to match Vue Router 3 behavior.
    // Vue Router 4's initial navigation is async, but components that read
    // $route in data() need it available immediately. Setting
    // `currentRoute.value` below also suppresses Vue Router 4's own initial
    // navigation (it checks `currentRoute === START_LOCATION`).
    const routerMode = options?.mode || 'hash';
    try {
      // Get the base path from the history object and strip it from the current path.
      // Vue Router 4's resolve() expects paths relative to the base, not absolute paths.
      const historyBase = router.options.history.base || '';

      let currentLocation;
      if (routerMode === 'abstract') {
        // Abstract-mode routers are decoupled from the browser URL (Vue
        // Router 3 never consulted window.location for them); resolving
        // window.location here fails to match and logs "No match found"
        // warnings. Resolve against the router's own base instead.
        currentLocation = historyBase || '/';
      } else {
        // Strip trailing slash from initial URL to match Vue Router 3 behavior
        const fullUrl = window.location.pathname + window.location.search + window.location.hash;
        const normalizedUrl = stripTrailingSlash(fullUrl);
        if (normalizedUrl !== fullUrl) {
          window.history.replaceState(window.history.state, '', normalizedUrl);
        }

        currentLocation = normalizeLocation(historyBase);
      }

      let resolved = router.resolve(currentLocation);

      // Vue Router 4's resolve() does not follow redirects (unlike Vue Router 3's
      // synchronous behavior). We need to manually follow redirect chains so that
      // components reading $route in data() see the final destination immediately.
      const maxRedirects = 10;
      let didRedirect = false;
      // Re-evaluated after every redirect hop: once the target carries lazy
      // components the synchronous path is abandoned (see below), and running
      // guards here as well would fire them twice.
      let hasLazyComponents = hasLazyMatchedComponents(resolved);
      for (let i = 0; !hasLazyComponents && i < maxRedirects; i += 1) {
        const lastMatched = resolved.matched[resolved.matched.length - 1];

        // resolve() does not execute beforeEnter guards. Synchronously invoke
        // them to mimic Vue Router 3 behavior where guards run before the
        // initial route is committed.
        const guardRedirect = runBeforeEnterGuards(resolved);

        if (guardRedirect) {
          resolved = router.resolve(guardRedirect);
          didRedirect = true;
        } else if (lastMatched?.redirect) {
          const { redirect } = lastMatched;
          const redirectTarget = typeof redirect === 'function' ? redirect(resolved) : redirect;
          resolved = router.resolve(redirectTarget);
          didRedirect = true;
        } else {
          break;
        }

        hasLazyComponents = hasLazyMatchedComponents(resolved);
      }

      // Lazy route components are only resolved during a real navigation:
      // pre-committing `currentRoute.value` would leave RouterView rendering
      // the raw loader function ("[object Promise]"). Skip the synchronous
      // pre-commit and let Vue Router's own initial navigation resolve the
      // loaders; $route-in-data() is moot there since the route component
      // doesn't exist until the loader settles.
      if (!hasLazyComponents) {
        router.currentRoute.value = resolved;

        // Forces afterEach hooks to run on the first route (e.g. updates to document.title)
        router.replace(resolved);

        // When a redirect was followed, update the browser URL to reflect the
        // final destination. Setting currentRoute.value above prevents Vue Router 4's
        // initial async navigation (which checks currentRoute === START_LOCATION),
        // so the URL would otherwise remain at the pre-redirect path.
        if (didRedirect) {
          history.replace(resolved.fullPath);
        }

        // Run the queued global guards manually (abstract mode stays at START
        // until the first explicit push, so it never ran them). Deferred to a
        // microtask so guards registered right after construction are picked
        // up too.
        if (routerMode !== 'abstract') {
          pendingInitialGuards = [];
          const initialRoute = resolved;
          Promise.resolve()
            .then(async () => {
              const guards = pendingInitialGuards;
              pendingInitialGuards = null;
              for (const guard of guards) {
                try {
                  // Sequential like the real guard pipeline; awaiting also
                  // contains rejections from async guards.
                  // eslint-disable-next-line no-await-in-loop
                  await guard(initialRoute, START_LOCATION, () => {});
                } catch {
                  // A throwing guard must not break router construction.
                }
              }
            })
            .catch(() => {});
        }
      }
    } catch {
      // If resolution fails, let the async navigation handle it
    }

    // eslint-disable-next-line no-constructor-return
    return new Proxy(router, {
      get(target, prop) {
        if (prop === 'history') {
          return target.options.history;
        }
        const result = target[prop];
        // eslint-disable-next-line no-underscore-dangle
        if (result?.__v_isRef) {
          return result.value;
        }

        return result;
      },
    });
  }

  static install() {
    Vue.mixin({
      beforeCreate() {
        const { app } = this.$.appContext;
        const { router } = this.$options;
        if (router && !installed.get(app)?.has(router)) {
          if (!installed.has(app)) {
            installed.set(app, new WeakSet());
          }
          installed.get(app).add(router);

          // Since we're doing "late initialization" we might already have RouterLink
          // for example, from router stubs. We need to maintain it
          const originalRouterLink = this.$.appContext.components.RouterLink;
          delete this.$.appContext.components.RouterLink;
          const originalGlobalProperties = app.config.globalProperties;
          const fakeGlobalProperties = {};
          app.config.globalProperties = fakeGlobalProperties;
          this.$.appContext.app.use(this.$options.router);

          app.config.globalProperties = originalGlobalProperties;
          app.config.globalProperties.$router = fakeGlobalProperties.$router;

          if (originalRouterLink) {
            this.$.appContext.components.RouterLink = originalRouterLink;
          }

          // Use a computed ref to maintain Vue 3 reactivity.
          const $routeComputed = computed(() => {
            const originalValue = fakeGlobalProperties.$route;
            if (!originalValue) return originalValue;
            const { params } = originalValue;
            if (!params) {
              return originalValue;
            }
            // Vue Router 4 returns arrays for repeatable params (e.g., /:id+),
            // but Vue Router 3 returned strings. Convert all array params to strings.
            const normalizedParams = Object.fromEntries(
              Object.entries(params).map(([key, value]) => [
                key,
                Array.isArray(value) ? value.join('/') : value,
              ]),
            );
            return {
              ...originalValue,
              params: normalizedParams,
            };
          });

          Object.defineProperty(app.config.globalProperties, '$route', {
            enumerable: true,
            get: () => $routeComputed.value,
          });
        }
      },
    });
  }
}
