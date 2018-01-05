import { parsePatch, applyPatches } from 'diff';
import { normalizeHeaders } from '../../../lib/utils/common_utils';
import { revertPatch } from '../../lib/diff/revert_patch';
import flash from '../../../flash';
import service from '../../services';
import * as types from '../mutation_types';
import router from '../../ide_router';
import {
  findEntry,
  setPageTitle,
  createTemp,
  findIndexOfFile,
} from '../utils';

export const closeFile = ({ commit, state, dispatch }, { file, force = false }) => {
  if ((file.changed || file.tempFile) && !force) return;

  const indexOfClosedFile = findIndexOfFile(state.openFiles, file);
  const fileWasActive = file.active;

  commit(types.TOGGLE_FILE_OPEN, file);
  commit(types.SET_FILE_ACTIVE, { file, active: false });

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.openFiles[nextIndexToOpen];

    dispatch('setFileActive', nextFileToOpen);
  } else if (!state.openFiles.length) {
    router.push(`/project/${file.projectId}/tree/${file.branchId}/`);
  }

  dispatch('getLastCommitData');
};

export const setFileActive = ({ commit, state, getters, dispatch }, file) => {
  const currentActiveFile = getters.activeFile;

  if (file.active) return;

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, { file: currentActiveFile, active: false });
  }

  commit(types.SET_FILE_ACTIVE, { file, active: true });
  dispatch('scrollToTab');

  // reset hash for line highlighting
  location.hash = '';

  commit(types.SET_CURRENT_PROJECT, file.projectId);
  commit(types.SET_CURRENT_BRANCH, file.branchId);
};

export const getFileData = ({ state, commit, dispatch }, file) => {
  return new Promise((resolve, reject) => {
    commit(types.TOGGLE_LOADING, file);
    service.getFileData(file.url)
      .then((res) => {
        const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

        setPageTitle(pageTitle);

        return res.json();
      })
      .then((data) => {
        commit(types.SET_FILE_DATA, { data, file });
        commit(types.TOGGLE_FILE_OPEN, file);
        dispatch('setFileActive', file);
        commit(types.TOGGLE_LOADING, file);
      })
      .catch(() => {
        commit(types.TOGGLE_LOADING, file);
        flash('Error loading file data. Please try again.', 'alert', document, null, false, true);
      });
  });
};
export const processFileMrDiff = ({ state, commit }, file) => {
  const patchObj = parsePatch(file.mrDiff);
  const transformedContent = applyPatch(file.raw, file.mrDiff);
  debugger;


export const setFileMrDiff = ({ state, commit }, { file, mrDiff }) => {
  commit(types.SET_FILE_MR_DIFF, { file, mrDiff });
};

export const getRawFileData = ({ commit, dispatch }, file) => service.getRawFileData(file)
  .then((raw) => {
    commit(types.SET_FILE_RAW_DATA, { file, raw });
  })
  .catch(() => flash('Error loading file content. Please try again.', 'alert', document, null, false, true));

export const setFileTargetBranch = ({ state, commit }, { file, targetBranch }) => {
  commit(types.SET_FILE_TARGET_BRANCH, { file, targetBranch, targetRawPath: file.rawPath.replace(file.branchId, targetBranch) });
};

export const getRawFileData = ({ commit, dispatch }, file) => {
  return new Promise((resolve, reject) => {
    service.getRawFileData(file)
      .then((raw) => {
        commit(types.SET_FILE_RAW_DATA, { file, raw });
        if (file.mrDiff) {
          service.getRawTargetFileData(file)
          .then((targetRaw) => {
            const patchObj = parsePatch(file.mrDiff);
            patchObj[0].hunks.forEach((hunk) => {
              console.log('H ', hunk);
              /*hunk.lines.forEach((line) => {
                if (line.substr(0, 1) === '+') {
                  line = '-' + line.substr(1);
                } else if (line.substr(0, 1) === '-') {
                  line = '+' + line.substr(1);
                }
              })*/
            });

            console.log('PATCH OBJ : ' + JSON.stringify(patchObj));

            const transformedContent = revertPatch(raw, patchObj, {
              compareLine: (lineNumber, line, operation, patchContent) => {
                const tempLine = line;
                //line = patchContent;
                //patchContent = tempLine;
                if (operation==='-') operation = '+';
                console.log('COMPARE : ' + line + ' - ' + operation + ' - ' + patchContent);
                return true;
              }
            });
            console.log('TRANSFORMED : ',transformedContent);
            commit(types.SET_FILE_TARGET_RAW_DATA, { file, raw: transformedContent });
            resolve(raw);
          });
        } else {
          resolve(raw);
        }
      })
      .catch(() => {
        flash('Error loading file content. Please try again.');
        reject();
      });
  });
};

export const getRawTargetFileData = ({ commit, dispatch }, file) =>
  service.getRawTargetFileData(file)
    .then((raw) => {
      commit(types.SET_FILE_TARGET_RAW_DATA, { file, raw });
    })
    .catch(() => flash('Error loading file content. Please try again.'));

export const changeFileContent = ({ commit }, { file, content }) => {
  commit(types.UPDATE_FILE_CONTENT, { file, content });
};

export const setFileLanguage = ({ state, commit }, { fileLanguage }) => {
  if (state.selectedFile) {
    commit(types.SET_FILE_LANGUAGE, { file: state.selectedFile, fileLanguage });
  }
};

export const setFileEOL = ({ state, commit }, { eol }) => {
  if (state.selectedFile) {
    commit(types.SET_FILE_EOL, { file: state.selectedFile, eol });
  }
};

export const setEditorPosition = ({ state, commit }, { editorRow, editorColumn }) => {
  if (state.selectedFile) {
    commit(types.SET_FILE_POSITION, { file: state.selectedFile, editorRow, editorColumn });
  }
};

export const setFileViewMode = ({ state, commit }, viewMode) => {
  commit(types.SET_FILE_VIEWMODE, { file: state.selectedFile, viewMode });
};

export const createTempFile = ({ state, commit, dispatch }, { projectId, branchId, parent, name, content = '', base64 = '' }) => {
  const path = parent.path !== undefined ? parent.path : '';
  // We need to do the replacement otherwise the web_url + file.url duplicate
  const newUrl = `/${projectId}/blob/${branchId}/${path}${path ? '/' : ''}${name}`;
  const file = createTemp({
    projectId,
    branchId,
    name: name.replace(`${path}/`, ''),
    path,
    type: 'blob',
    level: parent.level !== undefined ? parent.level + 1 : 0,
    changed: true,
    content,
    base64,
    url: newUrl,
  });

  if (findEntry(parent.tree, 'blob', file.name)) return flash(`The name "${file.name}" is already taken in this directory.`, 'alert', document, null, false, true);

  commit(types.CREATE_TMP_FILE, {
    parent,
    file,
  });
  commit(types.TOGGLE_FILE_OPEN, file);
  dispatch('setFileActive', file);

  if (!state.editMode && !file.base64) {
    dispatch('toggleEditMode', true);
  }

  router.push(`/project${file.url}`);

  return Promise.resolve(file);
};
