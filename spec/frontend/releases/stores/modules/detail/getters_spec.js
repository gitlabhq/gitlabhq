import * as getters from '~/releases/stores/modules/detail/getters';

describe('Release detail getters', () => {
  describe('releaseLinksToCreate', () => {
    it("returns an empty array if state.release doesn't exist", () => {
      const state = {};
      expect(getters.releaseLinksToCreate(state)).toEqual([]);
    });

    it("returns all release links that aren't empty", () => {
      const emptyLinks = [
        { url: '', name: '' },
        { url: ' ', name: '' },
        { url: ' ', name: ' ' },
        { url: '\r\n', name: '\t' },
      ];

      const nonEmptyLinks = [
        { url: 'https://example.com/1', name: 'Example 1' },
        { url: '', name: 'Example 2' },
        { url: 'https://example.com/3', name: '' },
      ];

      const state = {
        release: {
          assets: {
            links: [...emptyLinks, ...nonEmptyLinks],
          },
        },
      };

      expect(getters.releaseLinksToCreate(state)).toEqual(nonEmptyLinks);
    });
  });

  describe('releaseLinksToDelete', () => {
    it("returns an empty array if state.originalRelease doesn't exist", () => {
      const state = {};
      expect(getters.releaseLinksToDelete(state)).toEqual([]);
    });

    it('returns all links associated with the original release', () => {
      const originalLinks = [
        { url: 'https://example.com/1', name: 'Example 1' },
        { url: 'https://example.com/2', name: 'Example 2' },
      ];

      const state = {
        originalRelease: {
          assets: {
            links: originalLinks,
          },
        },
      };

      expect(getters.releaseLinksToDelete(state)).toEqual(originalLinks);
    });
  });

  describe('validationErrors', () => {
    describe('when the form is valid', () => {
      it('returns no validation errors', () => {
        const state = {
          release: {
            assets: {
              links: [
                { id: 1, url: 'https://example.com/valid', name: 'Link 1' },
                { id: 2, url: '', name: '' },
                { id: 3, url: '', name: ' ' },
                { id: 4, url: ' ', name: '' },
                { id: 5, url: ' ', name: ' ' },
              ],
            },
          },
        };

        const expectedErrors = {
          assets: {
            links: {
              1: {},
              2: {},
              3: {},
              4: {},
              5: {},
            },
          },
        };

        expect(getters.validationErrors(state)).toEqual(expectedErrors);
      });
    });

    describe('when the form is invalid', () => {
      let actualErrors;

      beforeEach(() => {
        const state = {
          release: {
            assets: {
              links: [
                // Duplicate URLs
                { id: 1, url: 'https://example.com/duplicate', name: 'Link 1' },
                { id: 2, url: 'https://example.com/duplicate', name: 'Link 2' },

                // the validation check ignores leading/trailing
                // whitespace and is case-insensitive
                { id: 3, url: '  \tHTTPS://EXAMPLE.COM/DUPLICATE\n\r\n  ', name: 'Link 3' },

                // Invalid URL format
                { id: 4, url: 'invalid', name: 'Link 4' },

                // Missing URL
                { id: 5, url: '', name: 'Link 5' },
                { id: 6, url: ' ', name: 'Link 6' },

                // Missing title
                { id: 7, url: 'https://example.com/valid/1', name: '' },
                { id: 8, url: 'https://example.com/valid/2', name: '  ' },
              ],
            },
          },
        };

        actualErrors = getters.validationErrors(state);
      });

      it('returns a validation errors if links share a URL', () => {
        const expectedErrors = {
          assets: {
            links: {
              1: { isDuplicate: true },
              2: { isDuplicate: true },
              3: { isDuplicate: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the URL is in the wrong format', () => {
        const expectedErrors = {
          assets: {
            links: {
              4: { isBadFormat: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the URL missing (and the title is populated)', () => {
        const expectedErrors = {
          assets: {
            links: {
              6: { isUrlEmpty: true },
              5: { isUrlEmpty: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });

      it('returns a validation error if the title missing (and the URL is populated)', () => {
        const expectedErrors = {
          assets: {
            links: {
              7: { isNameEmpty: true },
              8: { isNameEmpty: true },
            },
          },
        };

        expect(actualErrors).toMatchObject(expectedErrors);
      });
    });
  });

  describe('isValid', () => {
    // the value of state is not actually used by this getter
    const state = {};

    it('returns true when the form is valid', () => {
      const mockGetters = {
        validationErrors: {
          assets: {
            links: {
              1: {},
            },
          },
        },
      };

      expect(getters.isValid(state, mockGetters)).toBe(true);
    });

    it('returns false when the form is invalid', () => {
      const mockGetters = {
        validationErrors: {
          assets: {
            links: {
              1: { isNameEmpty: true },
            },
          },
        },
      };

      expect(getters.isValid(state, mockGetters)).toBe(false);
    });
  });
});
