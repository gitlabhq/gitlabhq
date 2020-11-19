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
      expect(pathGenerator(imageDetails, '/foo')).toBe('/foo/bar/registry/repository/1/tags/foo');
    });

    it.each`
      path                     | name         | result
      ${'foo/foo'}             | ${''}        | ${'/foo/foo/registry/repository/1/tags?format=json'}
      ${'foo/foo/foo'}         | ${'foo'}     | ${'/foo/foo/registry/repository/1/tags?format=json'}
      ${'baz/foo/foo/foo'}     | ${'foo'}     | ${'/baz/foo/foo/registry/repository/1/tags?format=json'}
      ${'baz/foo/foo/foo'}     | ${'foo'}     | ${'/baz/foo/foo/registry/repository/1/tags?format=json'}
      ${'foo/foo/baz/foo/foo'} | ${'foo/foo'} | ${'/foo/foo/baz/registry/repository/1/tags?format=json'}
      ${'foo/foo/baz/foo/bar'} | ${'foo/bar'} | ${'/foo/foo/baz/registry/repository/1/tags?format=json'}
      ${'baz/foo/foo'}         | ${'foo'}     | ${'/baz/foo/registry/repository/1/tags?format=json'}
      ${'baz/foo/bar'}         | ${'foo'}     | ${'/baz/foo/bar/registry/repository/1/tags?format=json'}
    `('returns the correct path when path is $path and name is $name', ({ name, path, result }) => {
      expect(pathGenerator({ id: 1, name, path })).toBe(result);
    });

    it('returns the url unchanged when imageDetails have no name', () => {
      const imageDetailsWithoutName = {
        path: 'foo/bar/baz',
        name: '',
        id: 1,
      };

      expect(pathGenerator(imageDetailsWithoutName)).toBe(
        '/foo/bar/baz/registry/repository/1/tags?format=json',
      );
    });
  });
});
