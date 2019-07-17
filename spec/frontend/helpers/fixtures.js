import fs from 'fs';
import path from 'path';

import { ErrorWithStack } from 'jest-util';

export function getFixture(relativePath) {
  const absolutePath = path.join(global.fixturesBasePath, relativePath);
  if (!fs.existsSync(absolutePath)) {
    throw new ErrorWithStack(
      `Fixture file ${relativePath} does not exist.

Did you run bin/rake frontend:fixtures?`,
      getFixture,
    );
  }

  return fs.readFileSync(absolutePath, 'utf8');
}

export const getJSONFixture = relativePath => JSON.parse(getFixture(relativePath));

export const resetHTMLFixture = () => {
  document.body.textContent = '';
};

export const setHTMLFixture = (htmlContent, resetHook = afterEach) => {
  document.body.outerHTML = htmlContent;
  resetHook(resetHTMLFixture);
};

export const loadHTMLFixture = (relativePath, resetHook = afterEach) => {
  const fileContent = getFixture(relativePath);
  setHTMLFixture(fileContent, resetHook);
};
