import { transformRoutes, normalizeLocation } from '~/lib/utils/vue3compat/vue_router_helper';

describe('Vue Router compat helper', () => {
  describe('normalizeLocation', () => {
    let originalPathname;
    let originalHash;

    beforeEach(() => {
      originalPathname = window.location.pathname;
      originalHash = window.location.hash;
    });

    afterEach(() => {
      window.history.replaceState({}, '', originalPathname + originalHash);
    });

    it('returns hash fragment content for hash mode', () => {
      window.history.replaceState({}, '', '/some/page#/my-tab');

      expect(normalizeLocation('#')).toBe('/my-tab');
    });

    it('returns "/" when no hash fragment in hash mode', () => {
      window.history.replaceState({}, '', '/some/page');

      expect(normalizeLocation('#')).toBe('/');
    });

    it('strips historyBase from pathname for web history mode', () => {
      window.history.replaceState({}, '', '/group/-/dashboard/list');

      expect(normalizeLocation('/group/-/dashboard')).toBe('/list');
    });

    it('returns full path when no historyBase', () => {
      window.history.replaceState({}, '', '/some/path?q=1#section');

      expect(normalizeLocation('')).toBe('/some/path?q=1#section');
    });

    it('returns "/" when pathname equals historyBase', () => {
      window.history.replaceState({}, '', '/app');

      expect(normalizeLocation('/app')).toBe('/');
    });
  });

  describe('transformRoutes', () => {
    const examples = [
      {
        name: 'simple route',
        routes: [{ name: 'index', path: '/' }],
        transformed: [{ name: 'index', path: '/' }],
      },
      {
        name: 'simple routes with children',
        routes: [
          {
            name: 'index',
            path: '/',
            children: [
              { name: 'list', path: '/list' },
              { name: 'details', path: '/details' },
            ],
          },
        ],
        transformed: [
          {
            name: 'index',
            path: '/',
            children: [
              { name: 'list', path: '/list' },
              { name: 'details', path: '/details' },
            ],
          },
        ],
      },
      {
        name: 'a catch-all route',
        routes: [{ name: 'any', path: '*' }],
        transformed: [{ name: 'any', path: '/:pathMatch(.*)*' }],
      },
      {
        name: 'with a catch-all route with a redirect',
        routes: [
          { name: 'index', path: '/' },
          { name: 'any', path: '*', redirect: '/' },
        ],
        transformed: [
          { name: 'index', path: '/' },
          { name: 'any', path: '/:pathMatch(.*)*', redirect: '/' },
        ],
      },
      {
        name: 'with a catch-all route in a child, adds extra redirect for empty path',
        routes: [
          {
            name: 'index',
            path: '/',
            children: [
              { name: 'list', path: '/list' },
              { name: 'details', path: '/details' },
              { name: 'other', path: '*', redirect: '/details' },
            ],
          },
        ],
        transformed: [
          {
            name: 'index',
            path: '/',
            children: [
              { name: 'list', path: '/list' },
              { name: 'details', path: '/details' },
              { name: 'other', path: ':pathMatch(.*)*', redirect: '/details' },
              { path: '', redirect: '/details' },
            ],
          },
        ],
      },
    ];

    it.each(examples)('$name', ({ routes, transformed }) => {
      expect(transformRoutes(routes)).toEqual(transformed);
    });
  });
});
