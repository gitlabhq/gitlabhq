import { SIDE_LEFT, SIDE_RIGHT } from './constants';
import { languages } from 'monaco-editor';
import { flatten } from 'lodash';

const toLowerCase = x => x.toLowerCase();

const monacoLanguages = languages.getLanguages();
const monacoExtensions = new Set(
  flatten(monacoLanguages.map(lang => lang.extensions?.map(toLowerCase) || [])),
);
const monacoMimetypes = new Set(
  flatten(monacoLanguages.map(lang => lang.mimetypes?.map(toLowerCase) || [])),
);
const monacoFilenames = new Set(
  flatten(monacoLanguages.map(lang => lang.filenames?.map(toLowerCase) || [])),
);

const KNOWN_TYPES = [
  {
    isText: false,
    isMatch(mimeType) {
      return mimeType.toLowerCase().includes('image/');
    },
  },
  {
    isText: true,
    isMatch(mimeType) {
      return mimeType.toLowerCase().includes('text/');
    },
  },
  {
    isText: true,
    isMatch(mimeType, fileName) {
      const fileExtension = fileName.includes('.') ? `.${fileName.split('.').pop()}` : '';

      return (
        monacoExtensions.has(fileExtension.toLowerCase()) ||
        monacoMimetypes.has(mimeType.toLowerCase()) ||
        monacoFilenames.has(fileName.toLowerCase())
      );
    },
  },
];

export function isTextFile(content, mimeType, fileName) {
  const knownType = KNOWN_TYPES.find(type => type.isMatch(mimeType, fileName));

  if (knownType) return knownType.isText;

  // does the string contain ascii characters only (ranges from space to tilde, tabs and new lines)
  const asciiRegex = /^[ -~\t\n\r]+$/;
  // for unknown types, determine the type by evaluating the file contents
  return asciiRegex.test(content);
}

export const createPathWithExt = p => {
  const ext = p.lastIndexOf('.') >= 0 ? p.substring(p.lastIndexOf('.') + 1) : '';

  return `${p.substring(1, p.lastIndexOf('.') + 1 || p.length)}${ext || '.js'}`;
};

export const trimPathComponents = path =>
  path
    .split('/')
    .map(s => s.trim())
    .join('/');

export function registerLanguages(def, ...defs) {
  if (defs.length) defs.forEach(lang => registerLanguages(lang));

  const languageId = def.id;

  languages.register(def);
  languages.setMonarchTokensProvider(languageId, def.language);
  languages.setLanguageConfiguration(languageId, def.conf);
}

export const otherSide = side => (side === SIDE_RIGHT ? SIDE_LEFT : SIDE_RIGHT);

export function addFinalNewline(content, eol = '\n') {
  return content.slice(-eol.length) !== eol ? `${content}${eol}` : content;
}

export function getPathParents(path) {
  const pathComponents = path.split('/');
  const paths = [];
  while (pathComponents.length) {
    pathComponents.pop();

    let parentPath = pathComponents.join('/');
    if (parentPath.startsWith('/')) parentPath = parentPath.slice(1);
    if (parentPath) paths.push(parentPath);
  }

  return paths;
}
