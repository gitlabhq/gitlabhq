const FILENAMES = ['index', 'readme'];

const MARKUP_EXTENSIONS = [
  'ad',
  'adoc',
  'asciidoc',
  'creole',
  'markdown',
  'md',
  'mdown',
  'mediawiki',
  'mkd',
  'mkdn',
  'org',
  'rdoc',
  'rst',
  'textile',
  'wiki',
];

const isRichReadme = (file) => {
  const re = new RegExp(`^(${FILENAMES.join('|')})\\.(${MARKUP_EXTENSIONS.join('|')})$`, 'i');
  return re.test(file.name);
};

const isPlainReadme = (file) => {
  const re = new RegExp(`^(${FILENAMES.join('|')})(\\.txt)?$`, 'i');
  return re.test(file.name);
};

export const readmeFile = (blobs) => blobs.find(isRichReadme) || blobs.find(isPlainReadme);
