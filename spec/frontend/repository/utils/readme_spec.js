import { readmeFile } from '~/repository/utils/readme';

describe('readmeFile', () => {
  describe('markdown files', () => {
    it('returns markdown file', () => {
      expect(readmeFile([{ name: 'README' }, { name: 'README.md' }])).toEqual({
        name: 'README.md',
      });

      expect(readmeFile([{ name: 'README' }, { name: 'index.md' }])).toEqual({
        name: 'index.md',
      });
    });
  });

  describe('plain files', () => {
    it('returns plain file', () => {
      expect(readmeFile([{ name: 'README' }, { name: 'TEST.md' }])).toEqual({
        name: 'README',
      });

      expect(readmeFile([{ name: 'readme' }, { name: 'TEST.md' }])).toEqual({
        name: 'readme',
      });
    });
  });

  describe('non-previewable file', () => {
    it('returns undefined', () => {
      expect(readmeFile([{ name: 'index.js' }, { name: 'TEST.md' }])).toBe(undefined);
    });
  });
});
