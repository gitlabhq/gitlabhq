import { execute } from './executor';
import { parse, parseQuery, parseYAML } from './parser';
import { present } from './presenter';
import { transform } from './transformer';

export const executeAndPresentQuery = async (glqlYaml, queryKey) => {
  const { query, config, variables } = await parse(glqlYaml);
  const data = await execute(query, variables);
  const transformed = await transform(data, config);
  return present(transformed, config, { queryKey });
};

export const presentPreview = async (glqlYaml, queryKey) => {
  const { config } = await parse(glqlYaml);
  const data = { project: { issues: { nodes: [] } } };
  const transformed = await transform(data, config);
  return present(transformed, config, { showPreview: true, queryKey });
};

export const loadMore = async (glqlYaml, cursorAfter) => {
  const parsedYaml = parseYAML(glqlYaml);
  const { query, config, variables } = await parseQuery(parsedYaml.query, {
    ...parsedYaml.config,
    cursorAfter,
    limit: 20,
  });
  const data = await execute(query, variables);
  return transform(data, config);
};
