import { pathGenerator } from '~/registry/explorer/utils';

describe('Utils', () => {
  describe('pathGenerator', () => {
    const imageDetails = {
      path: 'foo/bar/baz',
      name: 'baz',
      id: 1,
    };

    it('returns the fetch url when no ending is passed', () => {
      expect(pathGenerator(imageDetails)).toBe('/foo/bar/registry/repository/1/tags?format=json');
    });

    it('returns the url with an ending when is passed', () => {
      expect(pathGenerator(imageDetails, 'foo')).toBe('/foo/bar/registry/repository/1/foo');
    });
  });
});
