const FILENAMES = ['readme', 'index', '_index'];

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
const README_PATTERNS = [
  ...FILENAMES.flatMap((base) =>
    MARKUP_EXTENSIONS.map((ext) => new RegExp(`^${base}\\.${ext}$`, 'i')),
  ),
  ...FILENAMES.map((base) => new RegExp(`^${base}(\\.txt)?$`, 'i')),
];

export function readmeFile(blobs) {
  if (!blobs || !(blobs instanceof Array) || !blobs.length) {
    return undefined;
  }

  for (const pattern of README_PATTERNS) {
    const match = blobs.find((blob) => pattern.test(blob.name));

    if (match) {
      return match;
    }
  }

  return undefined;
}
