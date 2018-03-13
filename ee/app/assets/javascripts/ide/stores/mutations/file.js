import * as types from '../mutation_types';
import { findIndexOfFile } from '../utils';

export default {
  [types.SET_FILE_ACTIVE](state, { file, active }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          active,
        },
      },
    });
  },
  [types.TOGGLE_FILE_OPEN](state, file) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          opened: !state.entries[file.path].opened,
        },
      },
    });

    if (state.entries[file.path].opened) {
      state.openFiles.push(file.path);
    } else {
      state.openFiles.splice(state.openFiles.indexOf(file.path), 1);
    }
  },
  [types.SET_FILE_DATA](state, { data, file }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          id: data.id,
          blamePath: data.blame_path,
          commitsPath: data.commits_path,
          permalink: data.permalink,
          rawPath: data.raw_path,
          binary: data.binary,
          renderError: data.render_error,
        },
      },
    });
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          raw,
        },
      },
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { file, content }) {
    const changed = content !== file.raw;

    Object.assign(file, {
      content,
      changed,
    });
  },
  [types.SET_FILE_LANGUAGE](state, { file, fileLanguage }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          fileLanguage,
        },
      },
    });
  },
  [types.SET_FILE_EOL](state, { file, eol }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          eol,
        },
      },
    });
  },
  [types.SET_FILE_POSITION](state, { file, editorRow, editorColumn }) {
    Object.assign(state, {
      entries: {
        ...state.entries,
        [file.path]: {
          ...state.entries[file.path],
          editorRow,
          editorColumn,
        },
      },
    });
  },
  [types.DISCARD_FILE_CHANGES](state, file) {
    Object.assign(file, {
      content: file.raw,
      changed: false,
    });
  },
  [types.CREATE_TMP_FILE](state, { file, parent }) {
    parent.tree.push(file);
  },
  [types.ADD_FILE_TO_CHANGED](state, file) {
    state.changedFiles.push(file);
  },
  [types.REMOVE_FILE_FROM_CHANGED](state, file) {
    const indexOfChangedFile = findIndexOfFile(state.changedFiles, file);

    state.changedFiles.splice(indexOfChangedFile, 1);
  },
  [types.TOGGLE_FILE_CHANGED](state, { file, changed }) {
    Object.assign(file, {
      changed,
    });
  },
};
