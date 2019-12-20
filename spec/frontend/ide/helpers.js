import * as pathUtils from 'path';
import { decorateData } from '~/ide/stores/utils';
import state from '~/ide/stores/state';
import commitState from '~/ide/stores/modules/commit/state';
import mergeRequestsState from '~/ide/stores/modules/merge_requests/state';
import pipelinesState from '~/ide/stores/modules/pipelines/state';
import branchesState from '~/ide/stores/modules/branches/state';
import fileTemplatesState from '~/ide/stores/modules/file_templates/state';
import paneState from '~/ide/stores/modules/pane/state';

export const resetStore = store => {
  const newState = {
    ...state(),
    commit: commitState(),
    mergeRequests: mergeRequestsState(),
    pipelines: pipelinesState(),
    branches: branchesState(),
    fileTemplates: fileTemplatesState(),
    rightPane: paneState(),
  };
  store.replaceState(newState);
};

export const file = (name = 'name', id = name, type = '', parent = null) =>
  decorateData({
    id,
    type,
    icon: 'icon',
    url: 'url',
    name,
    path: parent ? `${parent.path}/${name}` : name,
    parentPath: parent ? parent.path : '',
    lastCommit: {},
  });

export const createEntriesFromPaths = paths =>
  paths
    .map(path => ({
      name: pathUtils.basename(path),
      dir: pathUtils.dirname(path),
      ext: pathUtils.extname(path),
    }))
    .reduce((entries, path, idx) => {
      const { name } = path;
      const parent = path.dir ? entries[path.dir] : null;
      const type = path.ext ? 'blob' : 'tree';
      const entry = file(name, (idx + 1).toString(), type, parent);
      return {
        [entry.path]: entry,
        ...entries,
      };
    }, {});
