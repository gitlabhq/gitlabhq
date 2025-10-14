import { isReasonableURL } from '~/projects/new_v2/utils';

describe('isReasonableURL', () => {
  describe('when URL is valid', () => {
    it.each([
      'https://gitlab.com/group/project.git',
      'http://gitlab.com/group/project.git',
      'git://gitlab.com/group/project.git',
      'https://github.com/user/repo',
      'http://example.com/repo.git',
      'git://example.com/path/to/repo',
    ])('returns true for %s', (url) => {
      expect(isReasonableURL(url)).toBe(true);
    });
  });

  describe('when URL is invalid', () => {
    it.each([
      5,
      'ftp://gitlab.com/repo.git',
      'ssh://git@gitlab.com/repo.git',
      'gitlab.com/group/project.git',
      'www.gitlab.com/group/project.git',
      '//gitlab.com/repo.git',
      'https://!!.com',
      'http:// y',
      'git://',
      'https://gitlab',
      'not a url',
      ' ',
    ])('returns false for invalid protocol or format: %s', (url) => {
      expect(isReasonableURL(url)).toBe(false);
    });
  });
});
