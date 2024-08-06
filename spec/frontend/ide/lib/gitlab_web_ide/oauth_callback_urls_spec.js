import {
  parseCallbackUrls,
  getOAuthCallbackUrl,
} from '~/ide/lib/gitlab_web_ide/oauth_callback_urls';
import { logError } from '~/lib/logger';
import { joinPaths } from '~/lib/utils/url_utility';
import { IDE_PATH, WEB_IDE_OAUTH_CALLBACK_URL_PATH } from '~/ide/constants';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/logger');

const MOCK_IDE_PATH = joinPaths(IDE_PATH, 'some/path');

describe('ide/lib/oauth_callback_urls', () => {
  describe('getOAuthCallbackUrl', () => {
    const mockPath = MOCK_IDE_PATH;
    const MOCK_RELATIVE_PATH = 'relative-path';
    const mockPathWithRelative = joinPaths(MOCK_RELATIVE_PATH, MOCK_IDE_PATH);

    const originalHref = window.location.href;

    afterEach(() => {
      setWindowLocation(originalHref);
    });

    const expectedBaseUrlWithRelative = joinPaths(window.location.origin, MOCK_RELATIVE_PATH);

    it.each`
      path                    | expectedCallbackBaseUrl
      ${mockPath}             | ${window.location.origin}
      ${mockPathWithRelative} | ${expectedBaseUrlWithRelative}
    `(
      'retrieves expected callback URL based on window url',
      ({ path, expectedCallbackBaseUrl }) => {
        setWindowLocation(path);

        const actual = getOAuthCallbackUrl();
        const expected = joinPaths(expectedCallbackBaseUrl, WEB_IDE_OAUTH_CALLBACK_URL_PATH);
        expect(actual).toEqual(expected);
      },
    );
  });
  describe('parseCallbackUrls', () => {
    it('parses the given JSON URL array and returns some metadata for them', () => {
      const actual = parseCallbackUrls(
        JSON.stringify([
          'https://gitlab.com/-/ide/oauth_redirect',
          'not a url',
          'https://gdk.test:3443/-/ide/oauth_redirect/',
          'https://gdk.test:3443/gitlab/-/ide/oauth_redirect#1234?query=foo',
          'https://example.com/not-a-real-one-/ide/oauth_redirectz',
        ]),
      );

      expect(actual).toEqual([
        {
          base: 'https://gitlab.com/',
          url: 'https://gitlab.com/-/ide/oauth_redirect',
        },
        {
          base: 'https://gdk.test:3443/',
          url: 'https://gdk.test:3443/-/ide/oauth_redirect/',
        },
        {
          base: 'https://gdk.test:3443/gitlab/',
          url: 'https://gdk.test:3443/gitlab/-/ide/oauth_redirect#1234?query=foo',
        },
        {
          base: 'https://example.com/',
          url: 'https://example.com/not-a-real-one-/ide/oauth_redirectz',
        },
      ]);
    });

    it('returns empty when given empty', () => {
      expect(parseCallbackUrls('')).toEqual([]);
      expect(logError).not.toHaveBeenCalled();
    });

    it('returns empty when not valid JSON', () => {
      expect(parseCallbackUrls('babar')).toEqual([]);
      expect(logError).toHaveBeenCalledWith('Failed to parse callback URLs JSON');
    });

    it('returns empty when not array JSON', () => {
      expect(parseCallbackUrls('{}')).toEqual([]);
    });
  });
});
