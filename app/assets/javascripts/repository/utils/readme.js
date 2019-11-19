const MARKDOWN_EXTENSIONS = ['mdown', 'mkd', 'mkdn', 'md', 'markdown'];
const ASCIIDOC_EXTENSIONS = ['adoc', 'ad', 'asciidoc'];
const OTHER_EXTENSIONS = ['textile', 'rdoc', 'org', 'creole', 'wiki', 'mediawiki', 'rst'];
const EXTENSIONS = [...MARKDOWN_EXTENSIONS, ...ASCIIDOC_EXTENSIONS, ...OTHER_EXTENSIONS];
const PLAIN_FILENAMES = ['readme', 'index'];
const FILE_REGEXP = new RegExp(
  `^(${PLAIN_FILENAMES.join('|')})(.(${EXTENSIONS.join('|')}))?$`,
  'i',
);
const PLAIN_FILE_REGEXP = new RegExp(`^(${PLAIN_FILENAMES.join('|')})`, 'i');
const EXTENSIONS_REGEXP = new RegExp(`.(${EXTENSIONS.join('|')})$`, 'i');

// eslint-disable-next-line import/prefer-default-export
export const readmeFile = blobs => {
  const readMeFiles = blobs.filter(f => f.name.search(FILE_REGEXP) !== -1);

  const previewableReadme = readMeFiles.find(f => f.name.search(EXTENSIONS_REGEXP) !== -1);
  const plainReadme = readMeFiles.find(f => f.name.search(PLAIN_FILE_REGEXP) !== -1);

  return previewableReadme || plainReadme;
};
