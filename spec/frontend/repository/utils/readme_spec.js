import { readmeFile } from '~/repository/utils/readme';

describe('readmeFile', () => {
  it('prefers README with markup over plain text README', () => {
    expect(readmeFile([{ name: 'README' }, { name: 'README.md' }])).toEqual({
      name: 'README.md',
    });
  });

  it('is case insensitive', () => {
    expect(readmeFile([{ name: 'README' }, { name: 'readme.rdoc' }])).toEqual({
      name: 'readme.rdoc',
    });
  });

  it('returns the first README found', () => {
    expect(readmeFile([{ name: 'INDEX.adoc' }, { name: 'README.md' }])).toEqual({
      name: 'INDEX.adoc',
    });
  });

  it('expects extension to be separated by dot', () => {
    expect(readmeFile([{ name: 'readmeXorg' }, { name: 'index.org' }])).toEqual({
      name: 'index.org',
    });
  });

  it('returns plain text README when there is no README with markup', () => {
    expect(readmeFile([{ name: 'README' }, { name: 'NOT_README.md' }])).toEqual({
      name: 'README',
    });
  });

  it('recognizes Readme.txt as a plain text README', () => {
    expect(readmeFile([{ name: 'Readme.txt' }])).toEqual({
      name: 'Readme.txt',
    });
  });

  it('returns undefined when there are no appropriate files', () => {
    expect(readmeFile([{ name: 'index.js' }, { name: 'md.README' }])).toBe(undefined);
    expect(readmeFile([])).toBe(undefined);
  });
});
