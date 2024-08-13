import { flatten, isString } from 'lodash';
import { languages } from 'monaco-editor';
import { setDiagnosticsOptions as yamlDiagnosticsOptions } from 'monaco-yaml';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { SIDE_LEFT, SIDE_RIGHT } from './constants';

const toLowerCase = (x) => x.toLowerCase();

const monacoLanguages = languages.getLanguages();
const monacoExtensions = new Set(
  flatten(monacoLanguages.map((lang) => lang.extensions?.map(toLowerCase) || [])),
);
const monacoMimetypes = new Set(
  flatten(monacoLanguages.map((lang) => lang.mimetypes?.map(toLowerCase) || [])),
);
const monacoFilenames = new Set(
  flatten(monacoLanguages.map((lang) => lang.filenames?.map(toLowerCase) || [])),
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

export function isTextFile({ name, raw, binary, content, mimeType = '' }) {
  // some file objects already have a `binary` property set on them. If so, use it first
  if (typeof binary === 'boolean') return !binary;

  const knownType = KNOWN_TYPES.find((type) => type.isMatch(mimeType, name));
  if (knownType) return knownType.isText;

  // does the string contain ascii characters only (ranges from space to tilde, tabs and new lines)
  const asciiRegex = /^[ -~\t\n\r]+$/;

  const fileContents = raw || content;

  // for unknown types, determine the type by evaluating the file contents
  return isString(fileContents) && (fileContents === '' || asciiRegex.test(fileContents));
}

export const createPathWithExt = (p) => {
  const ext = p.lastIndexOf('.') >= 0 ? p.substring(p.lastIndexOf('.') + 1) : '';

  return `${p.substring(1, p.lastIndexOf('.') + 1 || p.length)}${ext || '.js'}`;
};

export const trimPathComponents = (path) =>
  path
    .split('/')
    .map((s) => s.trim())
    .join('/');

export function registerLanguages(def, ...defs) {
  defs.forEach((lang) => registerLanguages(lang));

  const languageId = def.id;

  languages.register(def);
  languages.setMonarchTokensProvider(languageId, def.language);
  languages.setLanguageConfiguration(languageId, def.conf);
}

export function registerSchema(schema, options = {}) {
  const defaultOptions = {
    validate: true,
    enableSchemaRequest: true,
    hover: true,
    completion: true,
    schemas: [schema],
    ...options,
  };
  languages.json.jsonDefaults.setDiagnosticsOptions(defaultOptions);
  yamlDiagnosticsOptions(defaultOptions);
}

export const otherSide = (side) => (side === SIDE_RIGHT ? SIDE_LEFT : SIDE_RIGHT);

export function trimTrailingWhitespace(content) {
  return content.replace(/[^\S\r\n]+$/gm, '');
}

export function getPathParents(path, maxDepth = Infinity) {
  const pathComponents = path.split('/');
  const paths = [];

  let depth = 0;
  while (pathComponents.length && depth < maxDepth) {
    pathComponents.pop();

    let parentPath = pathComponents.join('/');
    if (parentPath.startsWith('/')) parentPath = parentPath.slice(1);
    if (parentPath) paths.push(parentPath);

    depth += 1;
  }

  return paths;
}

export function getPathParent(path) {
  return getPathParents(path, 1)[0];
}

export function getFileEOL(content = '') {
  return content.includes('\r\n') ? 'CRLF' : 'LF';
}

/**
 * Adds or increments the numeric suffix to a filename/branch name.
 * Retains underscore or dash before the numeric suffix if it already exists.
 *
 * Examples:
 *  hello -> hello-1
 *  hello-2425 -> hello-2425
 *  hello.md -> hello-1.md
 *  hello_2.md -> hello_3.md
 *  hello_ -> hello_1
 *  main-patch-22432 -> main-patch-22433
 *  patch_332 -> patch_333
 *
 * @param {string} filename File name or branch name
 * @param {number} [randomize] Should randomize the numeric suffix instead of auto-incrementing?
 */
export function addNumericSuffix(filename, randomize = false) {
  // eslint-disable-next-line max-params
  return filename.replace(/([ _-]?)(\d*)(\..+?$|$)/, (_, before, number, after) => {
    const n = randomize ? Math.random().toString().substring(2, 7).slice(-5) : Number(number) + 1;
    return `${before || '-'}${n}${after}`;
  });
}

export const measurePerformance = (
  mark,
  measureName,
  measureStart = undefined,
  measureEnd = mark,
  // eslint-disable-next-line max-params
) => {
  performanceMarkAndMeasure({
    mark,
    measures: [
      {
        name: measureName,
        start: measureStart,
        end: measureEnd,
      },
    ],
  });
};
