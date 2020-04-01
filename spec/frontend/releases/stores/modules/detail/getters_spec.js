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
});
