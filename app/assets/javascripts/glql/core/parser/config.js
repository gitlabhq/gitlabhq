import jsYaml from 'js-yaml';
import { transformAstToDisplayFields } from '../transformer/ast';
import { parseFields } from './fields';

export const parseYAMLConfig = (frontmatter, defaults = {}) => {
  const config = jsYaml.safeLoad(frontmatter) || {};

  config.display = config.display || 'list';
  config.fields = transformAstToDisplayFields(
    parseFields(config.fields || defaults?.fields.join(',')),
  );

  return config;
};
