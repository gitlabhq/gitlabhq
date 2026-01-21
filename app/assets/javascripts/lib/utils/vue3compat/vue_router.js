import Vue, { computed } from 'vue';
import {
  createRouter,
  createMemoryHistory,
  createWebHistory,
  createWebHashHistory,
} from '@gitlab/vue-router-vue3';

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

  return { history };
};

const base = () => null;

const toNewCatchAllPath = (path, { isRoot } = {}) => {
  if (path === '*') {
    const prefix = isRoot ? '/' : '';
    return `${prefix}:pathMatch(.*)*`;
  }
  return path;
};

const transformRoutes = (value, _routerOptions, transformOptions = { isRoot: true }) => {
  if (!value) return null;
  const newRoutes = value.map((route) => {
    const newRoute = {
      ...route,
      path: toNewCatchAllPath(route.path, transformOptions),
    };
    if (route.children) {
      newRoute.children = transformRoutes(route.children, _routerOptions, { isRoot: false }).routes;
    }
    // Vue Router 4 requires a component for catchall routes, even when using redirect.
    // Add a dummy component to suppress the warning.
    if (route.path === '*' && route.redirect && !route.component) {
      newRoute.component = { render: () => null };
    }
    return newRoute;
  });
  return { routes: newRoutes };
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
  routes: transformRoutes,
  scrollBehavior,
};

const transformOptions = (rawOptions = {}) => {
  const options = {
    mode: 'hash',
    ...rawOptions,
  };
  const defaultConfig = {
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

    // Patch history to strip trailing slashes (mimic Vue Router 3 behavior)
    const { history } = router.options;
    if (history) {
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
    }

    // Synchronously resolve initial route to match Vue Router 3 behavior.
    // Vue Router 4's initial navigation is async, but components that read
    // $route in data() need it available immediately.
    try {
      // Get the base path from the history object and strip it from the current path.
      // Vue Router 4's resolve() expects paths relative to the base, not absolute paths.
      const historyBase = router.options.history.base || '';
      let { pathname } = window.location;

      // Strip trailing slash from initial URL to match Vue Router 3 behavior
      const fullUrl = pathname + window.location.search + window.location.hash;
      const normalizedUrl = stripTrailingSlash(fullUrl);
      if (normalizedUrl !== fullUrl) {
        window.history.replaceState(window.history.state, '', normalizedUrl);
        pathname = window.location.pathname;
      }

      if (historyBase && pathname.startsWith(historyBase)) {
        pathname = pathname.slice(historyBase.length) || '/';
      }
      const currentLocation = pathname + window.location.search + window.location.hash;
      const resolved = router.resolve(currentLocation);

      router.currentRoute.value = resolved;
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
