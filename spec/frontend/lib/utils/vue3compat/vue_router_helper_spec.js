import { transformRoutes } from '~/lib/utils/vue3compat/vue_router_helper';

describe('Vue Router compat helper', () => {
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
