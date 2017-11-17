import * as types from '../mutation_types';
import {
  findIndexOfFile,
  createViewerStructure,
} from '../utils';

export default {
  [types.SET_FILE_ACTIVE](state, { file, active }) {
    Object.assign(file, {
      active,
    });
  },
  [types.TOGGLE_FILE_OPEN](state, file) {
    Object.assign(file, {
      opened: !file.opened,
    });

    if (file.opened) {
      state.openFiles.push(file);
    } else {
      state.openFiles.splice(findIndexOfFile(state.openFiles, file), 1);
    }
  },
  [types.SET_FILE_DATA](state, { data, file }) {
    Object.assign(file, {
      blamePath: data.blame_path,
      commitsPath: data.commits_path,
      permalink: data.permalink,
      rawPath: data.raw_path,
      binary: data.binary,
      renderError: data.render_error,
      currentViewer: data.rich_viewer ? 'rich' : 'simple',
      extension: data.extension,
    });

    createViewerStructure(file, 'rich', data);
    createViewerStructure(file, 'simple', data);
  },
  [types.SET_FILE_RAW_DATA](state, { file, raw }) {
    Object.assign(file, {
      raw,
    });
  },
  [types.UPDATE_FILE_CONTENT](state, { file, content }) {
    const changed = content !== file.raw;

    Object.assign(file, {
      content,
      changed,
    });
  },
  [types.DISCARD_FILE_CHANGES](state, file) {
    Object.assign(file, {
      content: '',
      changed: false,
    });
  },
  [types.CREATE_TMP_FILE](state, { file, parent }) {
    parent.tree.push(file);
  },
  [types.SET_FILE_VIEWER_DATA](state, { file, data }) {
    Object.assign(file[file.currentViewer], {
      html: data.html,
    });
  },
  [types.SET_CURRENT_FILE_VIEWER](state, { file, type }) {
    Object.assign(file, {
      currentViewer: type,
    });
  },
  [types.TOGGLE_FILE_VIEWER_LOADING](state, viewer) {
    Object.assign(viewer, {
      loading: !viewer.loading,
    });
  },
  [types.RESET_VIEWER_RENDER_ERROR](sstate, viewer) {
    Object.assign(viewer, {
      renderError: '',
      renderErrorReason: '',
    });
  },
};
