import * as types from '../mutation_types';

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
    Object.assign(state.entries[file.path], {
      id: data.id,
      blamePath: data.blame_path,
      commitsPath: data.commits_path,
      permalink: data.permalink,
      rawPath: data.raw_path,
      binary: data.binary,
      renderError: data.render_error,
      raw: null,
      baseRaw: null,
      html: data.html,
      size: data.size,
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(state.entries[file.path], {
      raw,
    });
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
    Object.assign(state.entries[file.path], {
      mrChange,
    });
  },
  [types.SET_FILE_VIEWMODE](state, { file, viewMode }) {
    Object.assign(state.entries[file.path], {
      viewMode,
    });
  },
  [types.DISCARD_FILE_CHANGES](state, path) {
    const stagedFile = state.stagedFiles.find(f => f.path === path);

    Object.assign(state.entries[path], {
      content: stagedFile ? stagedFile.content : state.entries[path].raw,
      changed: false,
    });
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
  [types.STAGE_CHANGE](state, path) {
    const stagedFile = state.stagedFiles.find(f => f.path === path);

    Object.assign(state, {
      changedFiles: state.changedFiles.filter(f => f.path !== path),
      entries: Object.assign(state.entries, {
        [path]: Object.assign(state.entries[path], {
          staged: true,
          changed: false,
        }),
      }),
    });

    if (stagedFile) {
      Object.assign(stagedFile, {
        ...state.entries[path],
      });
    } else {
      Object.assign(state, {
        stagedFiles: state.stagedFiles.concat({
          ...state.entries[path],
        }),
      });
    }
  },
  [types.UNSTAGE_CHANGE](state, path) {
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

      Object.assign(state, {
        changedFiles: state.changedFiles.concat(state.entries[path]),
      });
    }

    Object.assign(state, {
      stagedFiles: state.stagedFiles.filter(f => f.path !== path),
      entries: Object.assign(state.entries, {
        [path]: Object.assign(state.entries[path], {
          staged: false,
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
    const key = `${keyPrefix}-${file.key}`;
    const pendingTab = state.openFiles.find(f => f.key === key && f.pending);
    let openFiles = state.openFiles.map(f => Object.assign(f, { active: false, opened: false }));

    if (!pendingTab) {
      const openFile = openFiles.find(f => f.path === file.path);

      openFiles = openFiles.concat(openFile ? null : file).reduce((acc, f) => {
        if (!f) return acc;

        if (f.path === file.path) {
          return acc.concat({
            ...f,
            content: file.content,
            active: true,
            pending: true,
            opened: true,
            key,
          });
        }

        return acc.concat(f);
      }, []);
    } else {
      openFiles = state.openFiles.map(f =>
        Object.assign(f, { active: f.key === key, opened: f.key === key }),
      );
    }

    Object.assign(state, { openFiles });
  },
  [types.REMOVE_PENDING_TAB](state, file) {
    Object.assign(state, {
      openFiles: state.openFiles.filter(f => f.key !== file.key),
    });
  },
};
