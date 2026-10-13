import { getAbsolutePermalinkPath } from '~/repository/components/header_area/utils';
import * as urlUtility from '~/lib/utils/url_utility';

describe('getAbsolutePermalinkPath', () => {
  const permalinkPath = '/project/repo/-/blob/main/file.js';
  const baseUrl = 'https://gitlab.example.com';
  const absolutePath = 'https://gitlab.example.com/project/repo/-/blob/main/file.js';

  beforeEach(() => {
    jest.spyOn(urlUtility, 'getBaseURL').mockReturnValue(baseUrl);
    jest.spyOn(urlUtility, 'relativePathToAbsolute').mockReturnValue(absolutePath);
  });

  describe('when hash is not provided', () => {
    it.each([
      ['null', null],
      ['empty string', ''],
      ['undefined', undefined],
    ])('returns absolute path when hash is %s', (_, hash) => {
      expect(getAbsolutePermalinkPath(permalinkPath, hash)).toBe(absolutePath);
    });
  });

  describe('when handling different hash formats', () => {
    it.each([
      ['line number format', '#L6', '#L6'],
      ['line number range format', '#L10-19', '#L10-19'],
      [
        'anchor hash',
        '#developer-certificate-of-origin--license',
        '#developer-certificate-of-origin--license',
      ],
    ])('handles %s (%s)', (_, hash, expectedHash) => {
      expect(getAbsolutePermalinkPath(permalinkPath, hash)).toBe(`${absolutePath}${expectedHash}`);
    });
  });

  describe('when hash normalization is needed', () => {
    it.each([
      ['line number', 'L6', '#L6'],
      ['line number range', 'L10-19', '#L10-19'],
      [
        'complex anchor',
        'developer-certificate-of-origin--license',
        '#developer-certificate-of-origin--license',
      ],
    ])('normalizes %s hash by adding # prefix when missing', (_, hash, expectedHash) => {
      expect(getAbsolutePermalinkPath(permalinkPath, hash)).toBe(`${absolutePath}${expectedHash}`);
    });
  });

  describe('when additional query params are provided', () => {
    it('includes blame=1 in the permalink URL', () => {
      expect(getAbsolutePermalinkPath(permalinkPath, '#L6', { blame: '1' })).toBe(
        `${absolutePath}?blame=1#L6`,
      );
    });

    it('ignores empty or null query param values', () => {
      expect(getAbsolutePermalinkPath(permalinkPath, '#L6', { blame: '' })).toBe(
        `${absolutePath}#L6`,
      );
    });

    it('does not include blame when queryParams is empty', () => {
      expect(getAbsolutePermalinkPath(permalinkPath, '#L6', {})).toBe(`${absolutePath}#L6`);
    });
  });
});
