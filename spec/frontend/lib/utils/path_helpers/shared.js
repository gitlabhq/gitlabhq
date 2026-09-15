const withOrganizationPathOption = (args, organizationPath) => {
  const options = args.at(-1);

  return typeof options === 'object' && options !== null
    ? [...args.slice(0, -1), { ...options, organizationPath }]
    : [...args, { organizationPath }];
};

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

    describe('when the current page URL is organization scoped', () => {
      beforeEach(async () => {
        window.gon = {
          organization_path: 'acme',
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

      describe('when organizationPath is passed', () => {
        it.each(testCases)(
          '$pathHelperName returns /o/foo$baseExpected',
          async ({ pathHelperName, args, baseExpected }) => {
            const pathHelpers = await import(pathHelpersFilePath);

            expect(pathHelpers[pathHelperName](...withOrganizationPathOption(args, 'foo'))).toBe(
              `/o/foo${baseExpected}`,
            );
          },
        );
      });

      describe('when organizationPath is passed as null', () => {
        it.each(testCases)(
          '$pathHelperName returns $baseExpected',
          async ({ pathHelperName, args, baseExpected }) => {
            const pathHelpers = await import(pathHelpersFilePath);

            expect(pathHelpers[pathHelperName](...withOrganizationPathOption(args, null))).toBe(
              baseExpected,
            );
          },
        );
      });
    });

    describe('when relative_url_root is set and the current page URL is organization scoped', () => {
      beforeEach(async () => {
        window.gon = {
          relative_url_root: '/gitlab',
          organization_path: 'acme',
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

    describe('when the data context organization path is set', () => {
      beforeEach(async () => {
        window.gon = {
          data_context_organization_path: 'acme',
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

      describe('and organizationPath is passed', () => {
        it.each(testCases)(
          'ignores organizationPath argument, $pathHelperName returns /o/acme$baseExpected',
          async ({ pathHelperName, args, baseExpected }) => {
            const pathHelpers = await import(pathHelpersFilePath);

            expect(pathHelpers[pathHelperName](...withOrganizationPathOption(args, 'foo'))).toBe(
              `/o/acme${baseExpected}`,
            );
          },
        );
      });

      describe('and organizationPath is passed as null', () => {
        it.each(testCases)(
          'ignores organizationPath argument, $pathHelperName returns /o/acme$baseExpected',
          async ({ pathHelperName, args, baseExpected }) => {
            const pathHelpers = await import(pathHelpersFilePath);

            expect(pathHelpers[pathHelperName](...withOrganizationPathOption(args, null))).toBe(
              `/o/acme${baseExpected}`,
            );
          },
        );
      });

      describe('and the current page URL is scoped to a different organization', () => {
        beforeEach(async () => {
          window.gon = {
            data_context_organization_path: 'acme',
            organization_path: 'foo',
          };
          await setup();
        });

        it.each(testCases)(
          'uses data context, $pathHelperName returns /o/acme$baseExpected',
          async ({ pathHelperName, args, baseExpected }) => {
            const pathHelpers = await import(pathHelpersFilePath);

            expect(pathHelpers[pathHelperName](...args)).toBe(`/o/acme${baseExpected}`);
          },
        );
      });
    });
  });
};
