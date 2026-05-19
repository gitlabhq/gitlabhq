// To run this spec locally first run `bundle exec rake gitlab:js:routes`

describe('~/lib/utils/path_helpers/organizations', () => {
  const setup = async () => {
    await import('~/behaviors/configure_path_helpers');
  };

  beforeEach(() => {
    jest.resetModules();
  });

  afterEach(() => {
    window.gon = {};
  });

  describe('with no special configuration', () => {
    beforeEach(async () => {
      await setup();
    });

    it('organizationsPath returns /o', async () => {
      const { organizationsPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationsPath()).toBe('/o');
    });

    it('organizationPath returns /o/:organization_path/-/overview', async () => {
      const { organizationPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationPath('acme')).toBe('/o/acme/-/overview');
    });

    it('usersOrganizationPath returns /o/:organization_path/-/users', async () => {
      const { usersOrganizationPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(usersOrganizationPath('acme')).toBe('/o/acme/-/users');
    });
  });

  describe('when relative_url_root is set', () => {
    beforeEach(async () => {
      window.gon = { relative_url_root: '/gitlab' };
      await setup();
    });

    it('organizationsPath prepends the relative URL root', async () => {
      const { organizationsPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationsPath()).toBe('/gitlab/o');
    });

    it('organizationPath prepends the relative URL root', async () => {
      const { organizationPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationPath('acme')).toBe('/gitlab/o/acme/-/overview');
    });
  });

  describe('when current organization has scoped paths', () => {
    beforeEach(async () => {
      window.gon = {
        current_organization: {
          path: 'acme',
          has_scoped_paths: true,
        },
      };
      await setup();
    });

    it('organizationsPath is not affected by organization scoping', async () => {
      const { organizationsPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationsPath()).toBe('/o');
    });

    it('organizationPath is not affected by organization scoping', async () => {
      const { organizationPath } = await import('~/lib/utils/path_helpers/organizations');

      expect(organizationPath('other-org')).toBe('/o/other-org/-/overview');
    });
  });
});
