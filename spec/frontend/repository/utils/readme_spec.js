import { readmeFile } from '~/repository/utils/readme';

describe('readmeFile', () => {
  it.each([
    'readme',
    'README',
    'index',
    'INDEX',
    '_index',
    '_INDEX',
    'readme.md',
    'README.MD',
    'index.md',
    'INDEX.MD',
    '_index.md',
    '_INDEX.MD',
    'readme.txt',
    'README.TXT',
    'index.txt',
    'INDEX.TXT',
    '_index.txt',
    '_INDEX.TXT',
    'readme.rst',
    'index.asciidoc',
    '_index.org',
  ])('recognizes %s as a readme file', (filename) => {
    expect(readmeFile([{ name: filename }])).toEqual({
      name: filename,
    });
  });

  it('returns undefined when there are no readme-type files', () => {
    expect(
      readmeFile([
        { name: 'package.json' },
        { name: 'src/main.js' },
        { name: 'index.js' },
        { name: 'config.yml' },
        { name: 'readmeXorg' }, // Invalid - no dot separator
        { name: 'md.README' }, // Invalid - wrong order
      ]),
    ).toBe(undefined);
    expect(readmeFile([])).toBe(undefined);
    expect(readmeFile(null)).toBe(undefined);
  });

  it('prefers README with markup over plain text README', () => {
    expect(readmeFile([{ name: 'README' }, { name: 'README.md' }])).toEqual({
      name: 'README.md',
    });
  });

  it('prefers README over index', () => {
    expect(readmeFile([{ name: 'index.md' }, { name: 'README.md' }])).toEqual({
      name: 'README.md',
    });
  });

  it('prefers README over _index', () => {
    expect(readmeFile([{ name: '_index.md' }, { name: 'README.md' }])).toEqual({
      name: 'README.md',
    });
  });

  it('prefers index over _index', () => {
    expect(readmeFile([{ name: '_index.md' }, { name: 'index.md' }])).toEqual({
      name: 'index.md',
    });
  });

  it('is case insensitive', () => {
    expect(readmeFile([{ name: 'README' }, { name: 'readme.rdoc' }])).toEqual({
      name: 'readme.rdoc',
    });
  });

  it('returns the first README found', () => {
    expect(readmeFile([{ name: 'INDEX.adoc' }, { name: 'README.md' }])).toEqual({
      name: 'README.md',
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
});
