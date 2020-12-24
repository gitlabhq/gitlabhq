import { parseString } from 'editorconfig/src/lib/ini';
import minimatch from 'minimatch';
import { getPathParents } from '../../utils';

const dirname = (path) => path.replace(/\.editorconfig$/, '');

function isRootConfig(config) {
  return config.some(([pattern, rules]) => !pattern && rules?.root === 'true');
}

function getRulesForSection(path, [pattern, rules]) {
  if (!pattern) {
    return {};
  }
  if (minimatch(path, pattern, { matchBase: true })) {
    return rules;
  }

  return {};
}

function getRulesWithConfigs(filePath, configFiles = [], rules = {}) {
  if (!configFiles.length) return rules;

  const [{ content, path: configPath }, ...nextConfigs] = configFiles;
  const configDir = dirname(configPath);

  if (!filePath.startsWith(configDir)) return rules;

  const parsed = parseString(content);
  const isRoot = isRootConfig(parsed);
  const relativeFilePath = filePath.slice(configDir.length);

  const sectionRules = parsed.reduce(
    (acc, section) => Object.assign(acc, getRulesForSection(relativeFilePath, section)),
    {},
  );

  // prefer existing rules by overwriting to section rules
  const result = Object.assign(sectionRules, rules);

  return isRoot ? result : getRulesWithConfigs(filePath, nextConfigs, result);
}

export function getRulesWithTraversal(filePath, getFileContent) {
  const editorconfigPaths = [
    ...getPathParents(filePath).map((x) => `${x}/.editorconfig`),
    '.editorconfig',
  ];

  return Promise.all(
    editorconfigPaths.map((path) => getFileContent(path).then((content) => ({ path, content }))),
  ).then((results) =>
    getRulesWithConfigs(
      filePath,
      results.filter((x) => x.content),
    ),
  );
}
