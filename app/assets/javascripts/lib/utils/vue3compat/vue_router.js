import Vue from 'vue';
import {
  createRouter,
  createMemoryHistory,
  createWebHistory,
  createWebHashHistory,
} from 'vue-router-vue3';

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

const toNewCatchAllPath = (path) => {
  if (path === '*') return '/:pathMatch(.*)*';
  return path;
};

const routes = (value) => {
  if (!value) return null;
  const newRoutes = value.reduce(function handleRoutes(acc, route) {
    const newRoute = {
      ...route,
      path: toNewCatchAllPath(route.path),
    };
    if (route.children) {
      newRoute.children = route.children.reduce(handleRoutes, []);
    }
    acc.push(newRoute);
    return acc;
  }, []);
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
  routes,
  scrollBehavior,
};

const transformOptions = (options = {}) => {
  const defaultConfig = {
    routes: [],
    history: createWebHashHistory(),
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
          this.$.appContext.app.use(this.$options.router);
        }
      },
    });
  }
}
