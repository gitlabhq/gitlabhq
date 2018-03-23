import * as types from '../mutation_types';

export default {
  [types.SET_FILE_ACTIVE](state, { path, active }) {
    Object.assign(state.entries[path], {
      active,
    });

    Object.assign(state, {
      pendingTabs: state.pendingTabs.map(f => ({
        ...f,
        active: false,
      })),
    });
  },
  [types.TOGGLE_FILE_OPEN](state, path) {
    Object.assign(state.entries[path], {
      opened: !state.entries[path].opened,
    });

    if (state.entries[path].opened) {
      state.openFiles.push(state.entries[path]);
    } else {
      Object.assign(state, {
        openFiles: state.openFiles.filter(f => f.path !== path),
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
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(state.entries[file.path], {
      raw,
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { path, content }) {
    const changed = content !== state.entries[path].raw;

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
  [types.DISCARD_FILE_CHANGES](state, path) {
    Object.assign(state.entries[path], {
      content: state.entries[path].raw,
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
  [types.TOGGLE_FILE_CHANGED](state, { file, changed }) {
    Object.assign(state.entries[file.path], {
      changed,
    });
  },
  [types.ADD_PENDING_TAB](state, file) {
    const pendingTab = state.pendingTabs.find(f => f.path === file.path);

    if (pendingTab) {
      Object.assign(state, {
        pendingTabs: state.pendingTabs.map(tab => ({
          ...tab,
          active: !!pendingTab,
        })),
      });
    } else {
      Object.assign(state, {
        pendingTabs: state.pendingTabs.concat({
          ...file,
          active: true,
          pending: true,
          key: `pending-${file.key}`,
        }),
        openFiles: state.openFiles.map(f => ({
          ...f,
          active: false,
        })),
      });
    }
  },
  [types.REMOVE_PENDING_TAB](state, file) {
    Object.assign(state, {
      pendingTabs: state.pendingTabs.filter(f => f.path !== file.path),
    });
  },
};
