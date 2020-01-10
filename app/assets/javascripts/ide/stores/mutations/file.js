import * as types from '../mutation_types';
import { sortTree } from '../utils';
import { diffModes } from '../../constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  [types.SET_FILE_ACTIVE](state, { path, active }) {
    Object.assign(state.entries[path], {
      active,
      lastOpenedAt: new Date().getTime(),
    });

    if (active && !state.entries[path].pending) {
      Object.assign(state, {
        openFiles: state.openFiles.map(f =>
          Object.assign(f, { active: f.pending ? false : f.active }),
        ),
      });
    }
  },
  [types.TOGGLE_FILE_OPEN](state, path) {
    Object.assign(state.entries[path], {
      opened: !state.entries[path].opened,
    });

    if (state.entries[path].opened) {
      Object.assign(state, {
        openFiles: state.openFiles.filter(f => f.path !== path).concat(state.entries[path]),
      });
    } else {
      const file = state.entries[path];

      Object.assign(state, {
        openFiles: state.openFiles.filter(f => f.key !== file.key),
      });
    }
  },
  [types.SET_FILE_DATA](state, { data, file }) {
    const stateEntry = state.entries[file.path];
    const stagedFile = state.stagedFiles.find(f => f.path === file.path);
    const openFile = state.openFiles.find(f => f.path === file.path);
    const changedFile = state.changedFiles.find(f => f.path === file.path);

    [stateEntry, stagedFile, openFile, changedFile].forEach(f => {
      if (f) {
        Object.assign(
          f,
          convertObjectPropsToCamelCase(data, { dropKeys: ['path', 'name', 'raw', 'baseRaw'] }),
          {
            raw: (stateEntry && stateEntry.raw) || null,
            baseRaw: null,
          },
        );
      }
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    const openPendingFile = state.openFiles.find(
      f => f.path === file.path && f.pending && !(f.tempFile && !f.prevPath),
    );

    if (file.tempFile && file.content === '') {
      Object.assign(state.entries[file.path], {
        content: raw,
      });
    } else {
      Object.assign(state.entries[file.path], {
        raw,
      });
    }

    if (!openPendingFile) return;

    if (!openPendingFile.tempFile) {
      openPendingFile.raw = raw;
    } else if (openPendingFile.tempFile) {
      openPendingFile.content = raw;
    }
  },
  [types.SET_FILE_BASE_RAW_DATA](state, { file, baseRaw }) {
    Object.assign(state.entries[file.path], {
      baseRaw,
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { path, content }) {
    const stagedFile = state.stagedFiles.find(f => f.path === path);
    const rawContent = stagedFile ? stagedFile.content : state.entries[path].raw;
    const changed = content !== rawContent;

    Object.assign(state.entries[path], {
      content,
      changed,
    });
  },
  [types.SET_FILE_LANGUAGE](state, { file, fileLanguage }) {
    Object.assign(state.entries[file.path], {
      fileLanguage,
    });
  },
  [types.SET_FILE_EOL](state, { file, eol }) {
    Object.assign(state.entries[file.path], {
      eol,
    });
  },
  [types.SET_FILE_POSITION](state, { file, editorRow, editorColumn }) {
    Object.assign(state.entries[file.path], {
      editorRow,
      editorColumn,
    });
  },
  [types.SET_FILE_MERGE_REQUEST_CHANGE](state, { file, mrChange }) {
    let diffMode = diffModes.replaced;
    if (mrChange.new_file) {
      diffMode = diffModes.new;
    } else if (mrChange.deleted_file) {
      diffMode = diffModes.deleted;
    } else if (mrChange.renamed_file) {
      diffMode = diffModes.renamed;
    }
    Object.assign(state.entries[file.path], {
      mrChange: {
        ...mrChange,
        diffMode,
      },
    });
  },
  [types.SET_FILE_VIEWMODE](state, { file, viewMode }) {
    Object.assign(state.entries[file.path], {
      viewMode,
    });
  },
  [types.DISCARD_FILE_CHANGES](state, path) {
    const stagedFile = state.stagedFiles.find(f => f.path === path);
    const entry = state.entries[path];
    const { deleted } = entry;

    Object.assign(state.entries[path], {
      content: stagedFile ? stagedFile.content : state.entries[path].raw,
      changed: false,
      deleted: false,
    });

    if (deleted) {
      const parent = entry.parentPath
        ? state.entries[entry.parentPath]
        : state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

      parent.tree = sortTree(parent.tree.concat(entry));
    }
  },
  [types.ADD_FILE_TO_CHANGED](state, path) {
    Object.assign(state, {
      changedFiles: state.changedFiles.concat(state.entries[path]),
    });
  },
  [types.REMOVE_FILE_FROM_CHANGED](state, path) {
    Object.assign(state, {
      changedFiles: state.changedFiles.filter(f => f.path !== path),
    });
  },
  [types.STAGE_CHANGE](state, { path, diffInfo }) {
    const stagedFile = state.stagedFiles.find(f => f.path === path);

    Object.assign(state, {
      changedFiles: state.changedFiles.filter(f => f.path !== path),
      entries: Object.assign(state.entries, {
        [path]: Object.assign(state.entries[path], {
          staged: diffInfo.exists,
          changed: diffInfo.changed,
          tempFile: diffInfo.tempFile,
          deleted: diffInfo.deleted,
        }),
      }),
    });

    if (stagedFile) {
      Object.assign(stagedFile, { ...state.entries[path] });
    } else {
      state.stagedFiles = [...state.stagedFiles, { ...state.entries[path] }];
    }

    if (!diffInfo.exists) {
      state.stagedFiles = state.stagedFiles.filter(f => f.path !== path);
    }
  },
  [types.UNSTAGE_CHANGE](state, { path, diffInfo }) {
    const changedFile = state.changedFiles.find(f => f.path === path);
    const stagedFile = state.stagedFiles.find(f => f.path === path);

    if (!changedFile && stagedFile) {
      Object.assign(state.entries[path], {
        ...stagedFile,
        key: state.entries[path].key,
        active: state.entries[path].active,
        opened: state.entries[path].opened,
        changed: true,
      });

      state.changedFiles = state.changedFiles.concat(state.entries[path]);
    }

    if (!diffInfo.exists) {
      state.changedFiles = state.changedFiles.filter(f => f.path !== path);
    }

    Object.assign(state, {
      stagedFiles: state.stagedFiles.filter(f => f.path !== path),
      entries: Object.assign(state.entries, {
        [path]: Object.assign(state.entries[path], {
          staged: false,
          changed: diffInfo.changed,
          tempFile: diffInfo.tempFile,
          deleted: diffInfo.deleted,
        }),
      }),
    });
  },
  [types.TOGGLE_FILE_CHANGED](state, { file, changed }) {
    Object.assign(state.entries[file.path], {
      changed,
    });
  },
  [types.ADD_PENDING_TAB](state, { file, keyPrefix = 'pending' }) {
    state.entries[file.path].opened = false;
    state.entries[file.path].active = false;
    state.entries[file.path].lastOpenedAt = new Date().getTime();
    state.openFiles.forEach(f =>
      Object.assign(f, {
        opened: false,
        active: false,
      }),
    );
    state.openFiles = [
      {
        ...file,
        key: `${keyPrefix}-${file.key}`,
        pending: true,
        opened: true,
        active: true,
      },
    ];
  },
  [types.REMOVE_PENDING_TAB](state, file) {
    Object.assign(state, {
      openFiles: state.openFiles.filter(f => f.key !== file.key),
    });
  },
  [types.REMOVE_FILE_FROM_STAGED_AND_CHANGED](state, file) {
    Object.assign(state, {
      changedFiles: state.changedFiles.filter(f => f.key !== file.key),
      stagedFiles: state.stagedFiles.filter(f => f.key !== file.key),
    });

    Object.assign(state.entries[file.path], {
      changed: false,
      staged: false,
    });
  },
};
