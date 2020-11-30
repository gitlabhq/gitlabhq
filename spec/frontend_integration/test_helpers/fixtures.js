/* eslint-disable global-require, import/no-unresolved */
import { memoize } from 'lodash';

const createFactoryWithDefault = (fn, defaultValue) => () => {
  try {
    return fn();
  } catch {
    return defaultValue;
  }
};

const factory = {
  json: fn => createFactoryWithDefault(fn, { error: 'fixture not found' }),
  text: fn => createFactoryWithDefault(fn, 'Hello world\nHow are you today?\n'),
  binary: fn => createFactoryWithDefault(fn, ''),
};

export const getProject = factory.json(() => require('test_fixtures/api/projects/get.json'));
export const getEmptyProject = factory.json(() =>
  require('test_fixtures/api/projects/get_empty.json'),
);
export const getBranch = factory.json(() =>
  require('test_fixtures/api/projects/branches/get.json'),
);
export const getMergeRequests = factory.json(() =>
  require('test_fixtures/api/merge_requests/get.json'),
);
export const getRepositoryFiles = factory.json(() =>
  require('test_fixtures/projects_json/files.json'),
);
export const getPipelinesEmptyResponse = factory.json(() =>
  require('test_fixtures/projects_json/pipelines_empty.json'),
);
export const getCommit = memoize(() => getBranch().commit);

export const getBlobReadme = factory.text(() => require('test_fixtures/blob/text/README.md'));
export const getBlobZip = factory.binary(() => require('test_fixtures/blob/binary/Gemfile.zip'));
export const getBlobImage = factory.binary(() =>
  require('test_fixtures/blob/images/logo-white.png'),
);
