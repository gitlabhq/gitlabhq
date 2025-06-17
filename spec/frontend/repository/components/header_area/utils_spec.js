import { getAbsolutePermalinkPath } from '~/repository/components/header_area/utils';
import * as urlUtility from '~/lib/utils/url_utility';
import * as blobUtils from '~/blob/utils';

describe('getAbsolutePermalinkPath', () => {
  const permalinkPath = '/project/repo/-/blob/main/file.js';
  const baseUrl = 'https://gitlab.example.com';
  const absolutePath = 'https://gitlab.example.com/project/repo/-/blob/main/file.js';

  beforeEach(() => {
    jest.spyOn(urlUtility, 'getBaseURL').mockReturnValue(baseUrl);
    jest.spyOn(urlUtility, 'relativePathToAbsolute').mockReturnValue(absolutePath);
    jest.spyOn(blobUtils, 'getPageParamValue').mockReturnValue(null);
    jest.spyOn(blobUtils, 'getPageSearchString').mockReturnValue('');
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

  describe('when page parameters are present', () => {
    const searchString = '?plain=1';

    beforeEach(() => {
      blobUtils.getPageParamValue.mockReturnValue('1');
      blobUtils.getPageSearchString.mockReturnValue(searchString);
    });

    it.each([
      ['with # prefix', '#L6', '#L6'],
      ['without # prefix', 'L20', '#L20'],
      ['with empty hash', '', ''],
      ['with null hash', null, ''],
      ['with undefined hash', undefined, ''],
    ])('includes search string when hash is %s', (_, hash, expectedHash) => {
      expect(getAbsolutePermalinkPath(permalinkPath, hash)).toBe(
        `${absolutePath}${searchString}${expectedHash}`,
      );
    });
  });
});
