import createRouter from '~/explore/analytics_dashboards/router';
import DashboardView from 'ee_else_ce/explore/analytics_dashboards/pages/details.vue';
import DashboardsList from 'ee_else_ce/explore/analytics_dashboards/pages/list.vue';

// Vue Router 3 returns { route } from resolve(), Vue Router 4 returns the route directly.
const resolveRoute = (router, path) => {
  const resolved = router.resolve(path);
  return resolved.route ?? resolved;
};

describe('analytics dashboards router', () => {
  const basePath = '/explore/analytics_dashboards';
  const breadcrumbState = { name: 'Some dashboard' };

  let router;

  beforeEach(() => {
    router = createRouter(basePath, breadcrumbState);
  });

  it('uses the provided base path', () => {
    // Vue Router 3 stores base at router.options.base; Vue Router 4 at router.options.history.base
    const base = router.history?.base ?? router.options.history?.base ?? router.options.base;
    expect(base).toBe(basePath);
  });

  it('matches the root list route', () => {
    const route = resolveRoute(router, '/');

    expect(route.name).toBe('root');
    expect(route.matched[0].components.default).toBe(DashboardsList);
    expect(route.meta.root).toBe(true);
  });

  describe('dashboard-detail route', () => {
    it.each([
      ['a numeric custom-dashboard ID', '/3', '3'],
      ['a system-dashboard slug', '/merge_requests', 'merge_requests'],
    ])('matches %s', (_, path, slug) => {
      const route = resolveRoute(router, path);

      expect(route.name).toBe('dashboard-detail');
      expect(route.params.slug).toBe(slug);
      expect(route.matched[0].components.default).toBe(DashboardView);
    });

    it('returns the breadcrumb name from breadcrumbState', () => {
      const route = resolveRoute(router, '/merge_requests');

      expect(route.meta.getName()).toBe(breadcrumbState.name);
    });
  });
});
