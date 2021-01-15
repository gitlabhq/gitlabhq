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

Did you run bin/rake frontend:fixtures?`,
      getFixture,
    );
  }

  return fs.readFileSync(absolutePath, 'utf8');
}

export const getJSONFixture = (relativePath) => JSON.parse(getFixture(relativePath));

export const resetHTMLFixture = () => {
  document.head.innerHTML = '';
  document.body.innerHTML = '';
};

export const setHTMLFixture = (htmlContent, resetHook = afterEach) => {
  document.body.innerHTML = htmlContent;
  resetHook(resetHTMLFixture);
};

export const loadHTMLFixture = (relativePath, resetHook = afterEach) => {
  const fileContent = getFixture(relativePath);
  setHTMLFixture(fileContent, resetHook);
};
