import * as pathUtils from 'path';
import { WEB_IDE_OAUTH_CALLBACK_URL_PATH, commitActionTypes } from '~/ide/constants';
import { decorateData } from '~/ide/stores/utils';

// eslint-disable-next-line max-params
export const file = (name = 'name', id = name, type = '', parent = null) =>
  decorateData({
    id,
    type,
    icon: 'icon',
    name,
    path: parent ? `${parent.path}/${name}` : name,
    parentPath: parent ? parent.path : '',
  });

export const createEntriesFromPaths = (paths) =>
  paths
    .map((path) => ({
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

export const createTriggerChangeAction = (payload) => ({
  type: 'triggerFilesChange',
  ...(payload ? { payload } : {}),
});

export const createTriggerRenamePayload = (path, newPath) => ({
  type: commitActionTypes.move,
  path,
  newPath,
});

export const createTriggerUpdatePayload = (path) => ({
  type: commitActionTypes.update,
  path,
});

export const createTriggerRenameAction = (path, newPath) =>
  createTriggerChangeAction(createTriggerRenamePayload(path, newPath));

export const getMockCallbackUrl = () =>
  new URL(WEB_IDE_OAUTH_CALLBACK_URL_PATH, window.location.origin).toString();
