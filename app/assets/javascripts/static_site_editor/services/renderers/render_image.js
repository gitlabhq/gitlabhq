import { isAbsolute, getBaseURL, joinPaths } from '~/lib/utils/url_utility';

const canRender = ({ type }) => type === 'image';

let metadata;

const isRelativeToCurrentDirectory = basePath => !basePath.startsWith('/');

const extractSourceDirectory = url => {
  const sourceDir = /^(.+)\/([^/]+)$/.exec(url); // Extracts the base path and fileName from an image path
  return sourceDir || [null, null, url]; // If no source directory was extracted it means only a fileName was specified (e.g. url='file.png')
};

const parseCurrentDirectory = basePath => {
  const baseUrl = decodeURIComponent(metadata.baseUrl);
  const sourceDirectory = extractSourceDirectory(baseUrl)[1];
  const currentDirectory = sourceDirectory.split(`/-/sse/${metadata.branch}`)[1];

  return joinPaths(currentDirectory, basePath);
};

// For more context around this logic, please see the following comment:
// https://gitlab.com/gitlab-org/gitlab/-/issues/241166#note_409413500
const generateSourceDirectory = basePath => {
  let sourceDir = '';
  let defaultSourceDir = '';

  if (!basePath || isRelativeToCurrentDirectory(basePath)) {
    return parseCurrentDirectory(basePath);
  }

  if (!metadata.mounts.length) {
    return basePath;
  }

  metadata.mounts.forEach(({ source, target }) => {
    const hasTarget = target !== '';

    if (hasTarget && basePath.includes(target)) {
      sourceDir = source;
    } else if (!hasTarget) {
      defaultSourceDir = joinPaths(source, basePath);
    }
  });

  return sourceDir || defaultSourceDir;
};

const resolveFullPath = originalSrc => {
  if (isAbsolute(originalSrc)) {
    return originalSrc;
  }

  const sourceDirectory = extractSourceDirectory(originalSrc);
  const [, basePath, fileName] = sourceDirectory;
  const sourceDir = generateSourceDirectory(basePath);

  return joinPaths(getBaseURL(), metadata.project, '/-/raw/', metadata.branch, sourceDir, fileName);
};

const render = ({ destination: originalSrc, firstChild }, { skipChildren }) => {
  skipChildren();

  return {
    type: 'openTag',
    tagName: 'img',
    selfClose: true,
    attributes: {
      'data-original-src': !isAbsolute(originalSrc) ? originalSrc : '',
      src: resolveFullPath(originalSrc),
      alt: firstChild.literal,
    },
  };
};

const build = (mounts = [], project, branch, baseUrl) => {
  metadata = { mounts, project, branch, baseUrl };
  return { canRender, render };
};

export default { build };
