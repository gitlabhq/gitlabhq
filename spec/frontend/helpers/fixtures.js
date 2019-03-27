/* eslint-disable import/prefer-default-export, global-require, import/no-dynamic-require */

import fs from 'fs';
import path from 'path';

import { ErrorWithStack } from 'jest-util';

const fixturesBasePath = path.join(process.cwd(), 'spec', 'javascripts', 'fixtures');

export function getJSONFixture(relativePath, ee = false) {
  const absolutePath = path.join(fixturesBasePath, ee ? 'ee' : '', relativePath);
  if (!fs.existsSync(absolutePath)) {
    throw new ErrorWithStack(
      `Fixture file ${relativePath} does not exist.

Did you run bin/rake karma:fixtures?`,
      getJSONFixture,
    );
  }

  return require(absolutePath);
}
