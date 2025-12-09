import Vue from 'vue';
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

export default class VueRouterCompat {
  constructor(options) {
    // eslint-disable-next-line no-constructor-return
    return new Proxy(createRouter(transformOptions(options)), {
      get(target, prop) {
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

          Object.defineProperty(app.config.globalProperties, '$route', {
            enumerable: true,
            get: () => {
              const originalValue = fakeGlobalProperties.$route;
              if (!originalValue) return originalValue;
              const { params } = originalValue;
              return {
                ...originalValue,
                params: params
                  ? {
                      ...params,
                      // Vue-router 3 returns path as string
                      path: Array.isArray(params.path) ? params.path.join('/') : params.path,
                    }
                  : params,
              };
            },
          });
        }
      },
    });
  }
}
