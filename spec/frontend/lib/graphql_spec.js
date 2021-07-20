import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import { stripWhitespaceFromQuery } from '~/lib/graphql';
import { queryToObject } from '~/lib/utils/url_utility';

describe('stripWhitespaceFromQuery', () => {
  const operationName = 'getPipelineDetails';
  const variables = `{
    projectPath: 'root/abcd-dag',
    iid: '44'
  }`;

  const testQuery = getPipelineDetails.loc.source.body;
  const defaultPath = '/api/graphql';
  const encodedVariables = encodeURIComponent(variables);

  it('shortens the query argument by replacing multiple spaces and newlines with a single space', () => {
    const testString = `${defaultPath}?query=${encodeURIComponent(testQuery)}`;
    expect(testString.length > stripWhitespaceFromQuery(testString, defaultPath).length).toBe(true);
  });

  it('does not contract a single space', () => {
    const simpleSingleString = `${defaultPath}?query=${encodeURIComponent('fragment Nonsense')}`;
    expect(stripWhitespaceFromQuery(simpleSingleString, defaultPath)).toEqual(simpleSingleString);
  });

  it('works with a non-default path', () => {
    const newPath = 'another/graphql/path';
    const newPathSingleString = `${newPath}?query=${encodeURIComponent('fragment Nonsense')}`;
    expect(stripWhitespaceFromQuery(newPathSingleString, newPath)).toEqual(newPathSingleString);
  });

  it('does not alter other arguments', () => {
    const bareParams = `?query=${encodeURIComponent(
      testQuery,
    )}&operationName=${operationName}&variables=${encodedVariables}`;
    const testLongString = `${defaultPath}${bareParams}`;

    const processed = stripWhitespaceFromQuery(testLongString, defaultPath);
    const decoded = decodeURIComponent(processed);
    const params = queryToObject(decoded);

    expect(params.operationName).toBe(operationName);
    expect(params.variables).toBe(variables);
  });

  it('works when there are no query params', () => {
    expect(stripWhitespaceFromQuery(defaultPath, defaultPath)).toEqual(defaultPath);
  });

  it('works when the params do not include a query', () => {
    const paramsWithoutQuery = `${defaultPath}&variables=${encodedVariables}`;
    expect(stripWhitespaceFromQuery(paramsWithoutQuery, defaultPath)).toEqual(paramsWithoutQuery);
  });
});
