import { resolveOrganizationScope } from '~/lib/utils/path_helpers/utils';

describe('~/lib/utils/path_helpers/utils', () => {
  afterEach(() => {
    window.gon = {};
  });

  describe('resolveOrganizationScope', () => {
    describe('organizationPath option', () => {
      beforeEach(() => {
        window.gon = { organization_path: 'acme' };
      });

      it('takes precedence over the request organization path', () => {
        expect(resolveOrganizationScope(['foo/bar', { organizationPath: 'widgets' }])).toEqual({
          organizationPath: 'widgets',
          routeArgs: ['foo/bar', {}],
        });
      });

      it('opts out of organization scoping when null', () => {
        expect(resolveOrganizationScope(['foo/bar', { organizationPath: null }])).toEqual({
          organizationPath: null,
          routeArgs: ['foo/bar', {}],
        });
      });

      it('falls back to the request organization path when undefined', () => {
        expect(resolveOrganizationScope(['foo/bar', { organizationPath: undefined }])).toEqual({
          organizationPath: 'acme',
          routeArgs: ['foo/bar', {}],
        });
      });

      it('is stripped from the options so js-routes does not serialize it', () => {
        const { routeArgs } = resolveOrganizationScope([
          'foo/bar',
          { organizationPath: 'widgets', format: 'json' },
        ]);

        expect(routeArgs).toEqual(['foo/bar', { format: 'json' }]);
      });
    });

    describe('when the last argument is a serialized model rather than an options object', () => {
      // js-routes treats an object carrying `id`/`to_param`/`toParam` as a route
      // parameter, so `organizationPath` on it is the caller's data, not an option.
      it.each([
        ['id', { id: 5, organizationPath: 'widgets' }],
        ['to_param', { to_param: 'foo/bar', organizationPath: 'widgets' }],
        ['toParam', { toParam: 'foo/bar', organizationPath: 'widgets' }],
      ])('leaves an object identified by %s untouched', (_, model) => {
        window.gon = { organization_path: 'acme' };

        expect(resolveOrganizationScope([model])).toEqual({
          organizationPath: 'acme',
          routeArgs: [model],
        });
      });

      it('honours the `_options` escape hatch', () => {
        expect(
          resolveOrganizationScope([{ id: 5, _options: true, organizationPath: 'widgets' }]),
        ).toEqual({
          organizationPath: 'widgets',
          routeArgs: [{ id: 5, _options: true }],
        });
      });
    });

    describe('when a data context organization path is set', () => {
      beforeEach(() => {
        window.gon = { data_context_organization_path: 'acme', organization_path: 'widgets' };
      });

      it.each([
        ['a path', 'gizmos'],
        ['null', null],
        ['undefined', undefined],
      ])('ignores an organizationPath option of %s', (_, organizationPath) => {
        expect(resolveOrganizationScope(['foo/bar', { organizationPath }])).toEqual({
          organizationPath: 'acme',
          routeArgs: ['foo/bar', {}],
        });
      });
    });

    it.each([
      ['no arguments', []],
      ['no options object', ['foo/bar']],
      ['an array', [['foo', 'bar']]],
    ])('returns the request organization path and untouched args given %s', (_, args) => {
      window.gon = { organization_path: 'acme' };

      expect(resolveOrganizationScope(args)).toEqual({
        organizationPath: 'acme',
        routeArgs: args,
      });
    });
  });
});
