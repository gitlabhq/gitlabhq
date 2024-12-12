import jsYaml from 'js-yaml';
import { uniq } from 'lodash';
import { transformAstToDisplayFields } from '../transformer/ast';
import { parseFields } from './fields';

export const parseYAMLConfig = (frontmatter, defaults = {}) => {
  const config = jsYaml.safeLoad(frontmatter) || {};
  const parsedFields = transformAstToDisplayFields(
    parseFields(config.fields || defaults?.fields.join(',')),
  );

  config.fields = uniq(parsedFields);
  config.display = config.display || 'list';

  return config;
};
