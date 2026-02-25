const toNewCatchAllPath = (path, { isRoot } = {}) => {
  if (path === '*') {
    const prefix = isRoot ? '/' : '';
    return `${prefix}:pathMatch(.*)*`;
  }
  return path;
};

export const normalizeLocation = (historyBase = '') => {
  if (historyBase.includes('#')) {
    const hashIndex = window.location.href.indexOf('#');
    return hashIndex >= 0 ? window.location.href.slice(hashIndex + 1) || '/' : '/';
  }

  let { pathname } = window.location;
  if (historyBase && pathname.startsWith(historyBase)) {
    pathname = pathname.slice(historyBase.length) || '/';
  }
  return pathname + window.location.search + window.location.hash;
};

export const transformRoutes = (routes, _routerOptions, transformOptions = { isRoot: true }) => {
  if (!routes) return null;
  const newRoutes = [];
  routes.forEach((route) => {
    const newRoute = {
      ...route,
      path: toNewCatchAllPath(route.path, transformOptions),
    };
    if (route.children) {
      newRoute.children = transformRoutes(route.children, _routerOptions, { isRoot: false });
    }
    newRoutes.push(newRoute);

    // In Vue Router 3, a child catch-all `*` with redirect would also match when
    // the parent path was visited with no trailing child segment (e.g., `/`).
    // Vue Router 4's `:pathMatch(.*)*` does NOT match the empty string in child routes.
    // Add an empty-path sibling with the same redirect to preserve this behavior.
    if (route.path === '*' && route.redirect && !transformOptions.isRoot) {
      newRoutes.push({ path: '', redirect: route.redirect });
    }
  });

  return newRoutes;
};
