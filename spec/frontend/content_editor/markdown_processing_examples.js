import fs from 'fs';
import path from 'path';
import jsYaml from 'js-yaml';
import { getJSONFixture } from 'helpers/fixtures';

export const loadMarkdownApiResult = (testName) => {
  const fixturePathPrefix = `api/markdown/${testName}.json`;

  return getJSONFixture(fixturePathPrefix);
};

export const loadMarkdownApiExamples = () => {
  const apiMarkdownYamlPath = path.join(__dirname, '..', 'fixtures', 'api_markdown.yml');
  const apiMarkdownYamlText = fs.readFileSync(apiMarkdownYamlPath);
  const apiMarkdownExampleObjects = jsYaml.safeLoad(apiMarkdownYamlText);

  return apiMarkdownExampleObjects.map(({ name, context, markdown }) => [name, context, markdown]);
};
