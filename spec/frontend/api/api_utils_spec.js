import * as apiUtils from '~/api/api_utils';

describe('~/api/api_utils.js', () => {
  describe('buildApiUrl', () => {
    beforeEach(() => {
      window.gon = {
        api_version: 'v7',
      };
    });

    it('returns a URL with the correct API version', () => {
      expect(apiUtils.buildApiUrl('/api/:version/users/:id/status')).toEqual(
        '/api/v7/users/:id/status',
      );
    });

    it('only replaces the first instance of :version in the URL', () => {
      expect(apiUtils.buildApiUrl('/api/:version/projects/:id/packages/:version')).toEqual(
        '/api/v7/projects/:id/packages/:version',
      );
    });

    it('ensures the URL is prefixed with a /', () => {
      expect(apiUtils.buildApiUrl('api/:version/projects/:id')).toEqual('/api/v7/projects/:id');
    });

    describe('when gon includes a relative_url_root property', () => {
      beforeEach(() => {
        window.gon.relative_url_root = '/relative/root';
      });

      it('returns a URL with the correct relative root URL and API version', () => {
        expect(apiUtils.buildApiUrl('/api/:version/users/:id/status')).toEqual(
          '/relative/root/api/v7/users/:id/status',
        );
      });
    });
  });
});
