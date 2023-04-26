import fs from 'fs';
import path from 'path';

import { ErrorWithStack } from 'jest-util';

export function getFixture(relativePath) {
  const basePath = relativePath.startsWith('static/')
    ? global.staticFixturesBasePath
    : global.fixturesBasePath;
  const absolutePath = path.join(basePath, relativePath);
  if (!fs.existsSync(absolutePath)) {
    throw new ErrorWithStack(
      `Fixture file ${relativePath} does not exist.

Did you run bin/rake frontend:fixtures? You can also download fixtures from the gitlab-org/gitlab package registry.

See https://docs.gitlab.com/ee/development/testing_guide/frontend_testing.html#download-fixtures for more info.
`,
      getFixture,
    );
  }

  return fs.readFileSync(absolutePath, 'utf8');
}

export const resetHTMLFixture = () => {
  document.head.innerHTML = '';
  document.body.innerHTML = '';
};

export const setHTMLFixture = (htmlContent) => {
  document.body.innerHTML = htmlContent;
};

export const loadHTMLFixture = (relativePath) => {
  setHTMLFixture(getFixture(relativePath));
};
