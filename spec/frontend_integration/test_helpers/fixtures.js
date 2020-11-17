/* eslint-disable global-require, import/no-unresolved */
import { memoize } from 'lodash';

export const getProject = () => require('test_fixtures/api/projects/get.json');
export const getBranch = () => require('test_fixtures/api/projects/branches/get.json');
export const getMergeRequests = () => require('test_fixtures/api/merge_requests/get.json');
export const getRepositoryFiles = () => require('test_fixtures/projects_json/files.json');
export const getPipelinesEmptyResponse = () =>
  require('test_fixtures/projects_json/pipelines_empty.json');
export const getCommit = memoize(() => getBranch().commit);
