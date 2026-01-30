// eslint-disable-next-line jest/no-export
export const sharedPathHelperTests = ({ pathHelpersFilePath, testCases }) => {
  describe(pathHelpersFilePath, () => {
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

      it.each(testCases)(
        '$pathHelperName returns $baseExpected',
        async ({ pathHelperName, args, baseExpected }) => {
          const pathHelpers = await import(pathHelpersFilePath);

          expect(pathHelpers[pathHelperName](...args)).toBe(baseExpected);
        },
      );
    });

    describe('when relative_url_root is set', () => {
      beforeEach(async () => {
        window.gon = {
          relative_url_root: '/gitlab',
        };
        await setup();
      });

      it.each(testCases)(
        '$pathHelperName returns /gitlab$baseExpected',
        async ({ pathHelperName, args, baseExpected }) => {
          const pathHelpers = await import(pathHelpersFilePath);

          expect(pathHelpers[pathHelperName](...args)).toBe(`/gitlab${baseExpected}`);
        },
      );
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

      it.each(testCases)(
        '$pathHelperName returns /o/acme$baseExpected',
        async ({ pathHelperName, args, baseExpected }) => {
          const pathHelpers = await import(pathHelpersFilePath);

          expect(pathHelpers[pathHelperName](...args)).toBe(`/o/acme${baseExpected}`);
        },
      );
    });

    describe('when relative_url_root is set and current organization has scoped paths', () => {
      beforeEach(async () => {
        window.gon = {
          relative_url_root: '/gitlab',
          current_organization: {
            path: 'acme',
            has_scoped_paths: true,
          },
        };
        await setup();
      });

      it.each(testCases)(
        '$pathHelperName returns /gitlab/o/acme$baseExpected',
        async ({ pathHelperName, args, baseExpected }) => {
          const pathHelpers = await import(pathHelpersFilePath);

          expect(pathHelpers[pathHelperName](...args)).toBe(`/gitlab/o/acme${baseExpected}`);
        },
      );
    });
  });
};
