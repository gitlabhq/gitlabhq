import { createLink, generateHLJSOpenTag } from './dependency_linker_util';

const PROTOCOL = 'https://';
const GODOCS_DOMAIN = 'godoc.org/';
const REPO_PATH = '/tree/master/';
const GODOCS_REGEX = /golang.org/;
const GITLAB_REPO_PATH = `/_${REPO_PATH}`;
const REPO_REGEX = `[^/'"]+/[^/'"]+`;
const NESTED_REPO_REGEX = '([^/]+/)+[^/]+?';
const GITHUB_REPO_REGEX = new RegExp(`(github.com/${REPO_REGEX})/(.+)`);
const GITLAB_REPO_REGEX = new RegExp(`(gitlab.com/${REPO_REGEX})/(.+)`);
const GITLAB_NESTED_REPO_REGEX = new RegExp(`(gitlab.com/${NESTED_REPO_REGEX}).git/(.+)`);
const attrOpenTag = generateHLJSOpenTag('attr');
const stringOpenTag = generateHLJSOpenTag('string');
const closeTag = '&quot;</span>';
const importPathString =
  'ImportPath&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span>';

const DEPENDENCY_REGEX = new RegExp(
  /*
   * Detects dependencies inside of content that is highlighted by Highlight.js
   * Example: <span class="hljs-attr">&quot;ImportPath&quot;</span><span class="hljs-punctuation">:</span><span class=""> </span><span class="hljs-string">&quot;github.com/ayufan/golang-kardianos-service&quot;</span>
   * Group 1:  github.com/ayufan/golang-kardianos-service
   */
  `${importPathString}${stringOpenTag}(.*)${closeTag}`,
  'gm',
);

const replaceRepoPath = (dependency, regex, repoPath) =>
  dependency.replace(regex, (_, repo, path) => `${PROTOCOL}${repo}${repoPath}${path}`);

const regexConfigs = [
  {
    matcher: GITHUB_REPO_REGEX,
    resolver: (dep) => replaceRepoPath(dep, GITHUB_REPO_REGEX, REPO_PATH),
  },
  {
    matcher: GITLAB_REPO_REGEX,
    resolver: (dep) => replaceRepoPath(dep, GITLAB_REPO_REGEX, GITLAB_REPO_PATH),
  },
  {
    matcher: GITLAB_NESTED_REPO_REGEX,
    resolver: (dep) => replaceRepoPath(dep, GITLAB_NESTED_REPO_REGEX, GITLAB_REPO_PATH),
  },
  {
    matcher: GODOCS_REGEX,
    resolver: (dep) => `${PROTOCOL}${GODOCS_DOMAIN}${dep}`,
  },
];

const getLinkHref = (dependency) => {
  const regexConfig = regexConfigs.find((config) => dependency.match(config.matcher));
  return regexConfig ? regexConfig.resolver(dependency) : `${PROTOCOL}${dependency}`;
};

const handleReplace = (dependency) => {
  const linkHref = getLinkHref(dependency);
  const link = createLink(linkHref, dependency);
  return `${importPathString}${attrOpenTag}${link}${closeTag}`;
};

export default (result) => {
  return result.value.replace(DEPENDENCY_REGEX, (_, dependency) => handleReplace(dependency));
};
