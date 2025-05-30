import { execute } from './executor';
import { parse } from './parser';
import { present } from './presenter';
import { transform } from './transformer/data';

export const executeAndPresentQuery = async (glqlQuery, queryKey) => {
  const { query, config, variables } = await parse(glqlQuery);
  const data = await execute(query, variables);
  const transformed = transform(data, config);
  return present(transformed, config, { queryKey });
};

export const presentPreview = async (glqlQuery, queryKey) => {
  const { config } = await parse(glqlQuery);
  const data = { project: { issues: { nodes: [] } } };
  const transformed = transform(data, config);
  return present(transformed, config, { isPreview: true, queryKey });
};
