import * as pathUtils from 'path';
import { decorateData } from '~/ide/stores/utils';

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
