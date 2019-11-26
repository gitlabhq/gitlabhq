import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  findDiffFile,
  addLineReferences,
  removeMatchLine,
  addContextLines,
  prepareDiffData,
  isDiscussionApplicableToLine,
  updateLineInFile,
} from './utils';
import * as types from './mutation_types';

export default {
  [types.SET_BASE_CONFIG](state, options) {
    const {
      endpoint,
      endpointMetadata,
      endpointBatch,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
    } = options;
    Object.assign(state, {
      endpoint,
      endpointMetadata,
      endpointBatch,
      projectPath,
      dismissEndpoint,
      showSuggestPopover,
    });
  },

  [types.SET_LOADING](state, isLoading) {
    Object.assign(state, { isLoading });
  },

  [types.SET_BATCH_LOADING](state, isBatchLoading) {
    Object.assign(state, { isBatchLoading });
  },

  [types.SET_DIFF_DATA](state, data) {
    prepareDiffData(data);

    Object.assign(state, {
      ...convertObjectPropsToCamelCase(data),
    });
  },

  [types.SET_DIFF_DATA_BATCH](state, data) {
    prepareDiffData(data);

    state.diffFiles.push(...data.diff_files);
  },

  [types.RENDER_FILE](state, file) {
    Object.assign(file, {
      renderIt: true,
    });
  },

  [types.SET_MERGE_REQUEST_DIFFS](state, mergeRequestDiffs) {
    Object.assign(state, {
      mergeRequestDiffs,
    });
  },

  [types.SET_DIFF_VIEW_TYPE](state, diffViewType) {
    Object.assign(state, { diffViewType });
  },

  [types.TOGGLE_LINE_HAS_FORM](state, { lineCode, fileHash, hasForm }) {
    const diffFile = state.diffFiles.find(f => f.file_hash === fileHash);

    if (!diffFile) return;

    if (diffFile.highlighted_diff_lines) {
      diffFile.highlighted_diff_lines.find(l => l.line_code === lineCode).hasForm = hasForm;
    }

    if (diffFile.parallel_diff_lines) {
      const line = diffFile.parallel_diff_lines.find(l => {
        const { left, right } = l;

        return (left && left.line_code === lineCode) || (right && right.line_code === lineCode);
      });

      if (line.left && line.left.line_code === lineCode) {
        line.left.hasForm = hasForm;
      }

      if (line.right && line.right.line_code === lineCode) {
        line.right.hasForm = hasForm;
      }
    }
  },

  [types.ADD_CONTEXT_LINES](state, options) {
    const { lineNumbers, contextLines, fileHash, isExpandDown, nextLineNumbers } = options;
    const { bottom } = options.params;
    const diffFile = findDiffFile(state.diffFiles, fileHash);

    removeMatchLine(diffFile, lineNumbers, bottom);

    const lines = addLineReferences(
      contextLines,
      lineNumbers,
      bottom,
      isExpandDown,
      nextLineNumbers,
    ).map(line => {
      const lineCode =
        line.type === 'match'
          ? `${fileHash}_${line.meta_data.old_pos}_${line.meta_data.new_pos}_match`
          : line.line_code || `${fileHash}_${line.old_line}_${line.new_line}`;
      return {
        ...line,
        line_code: lineCode,
        discussions: line.discussions || [],
        hasForm: false,
      };
    });

    addContextLines({
      inlineLines: diffFile.highlighted_diff_lines,
      parallelLines: diffFile.parallel_diff_lines,
      contextLines: lines,
      bottom,
      lineNumbers,
      isExpandDown,
    });
  },

  [types.ADD_COLLAPSED_DIFFS](state, { file, data }) {
    prepareDiffData(data);
    const [newFileData] = data.diff_files.filter(f => f.file_hash === file.file_hash);
    const selectedFile = state.diffFiles.find(f => f.file_hash === file.file_hash);
    Object.assign(selectedFile, { ...newFileData });
  },

  [types.EXPAND_ALL_FILES](state) {
    state.diffFiles = state.diffFiles.map(file => ({
      ...file,
      viewer: {
        ...file.viewer,
        collapsed: false,
      },
    }));
  },

  [types.SET_LINE_DISCUSSIONS_FOR_FILE](state, { discussion, diffPositionByLineCode, hash }) {
    const { latestDiff } = state;

    const discussionLineCode = discussion.line_code;
    const fileHash = discussion.diff_file.file_hash;
    const lineCheck = line =>
      line.line_code === discussionLineCode &&
      isDiscussionApplicableToLine({
        discussion,
        diffPosition: diffPositionByLineCode[line.line_code],
        latestDiff,
      });
    const mapDiscussions = (line, extraCheck = () => true) => ({
      ...line,
      discussions: extraCheck()
        ? line.discussions
            .filter(() => !line.discussions.some(({ id }) => discussion.id === id))
            .concat(lineCheck(line) ? discussion : line.discussions)
        : [],
    });

    const setDiscussionsExpanded = line => {
      const isLineNoteTargeted = line.discussions.some(
        disc => disc.notes && disc.notes.find(note => hash === `note_${note.id}`),
      );

      return {
        ...line,
        discussionsExpanded:
          line.discussions && line.discussions.length
            ? line.discussions.some(disc => !disc.resolved) || isLineNoteTargeted
            : false,
      };
    };

    state.diffFiles = state.diffFiles.map(diffFile => {
      if (diffFile.file_hash === fileHash) {
        const file = { ...diffFile };

        if (file.highlighted_diff_lines) {
          file.highlighted_diff_lines = file.highlighted_diff_lines.map(line =>
            setDiscussionsExpanded(lineCheck(line) ? mapDiscussions(line) : line),
          );
        }

        if (file.parallel_diff_lines) {
          file.parallel_diff_lines = file.parallel_diff_lines.map(line => {
            const left = line.left && lineCheck(line.left);
            const right = line.right && lineCheck(line.right);

            if (left || right) {
              return {
                ...line,
                left: line.left ? setDiscussionsExpanded(mapDiscussions(line.left)) : null,
                right: line.right
                  ? setDiscussionsExpanded(mapDiscussions(line.right, () => !left))
                  : null,
              };
            }

            return line;
          });
        }

        if (!file.parallel_diff_lines || !file.highlighted_diff_lines) {
          file.discussions = (file.discussions || [])
            .filter(d => d.id !== discussion.id)
            .concat(discussion);
        }

        return file;
      }

      return diffFile;
    });
  },

  [types.REMOVE_LINE_DISCUSSIONS_FOR_FILE](state, { fileHash, lineCode }) {
    const selectedFile = state.diffFiles.find(f => f.file_hash === fileHash);
    if (selectedFile) {
      updateLineInFile(selectedFile, lineCode, line =>
        Object.assign(line, {
          discussions: line.discussions.filter(discussion => discussion.notes.length),
        }),
      );

      if (selectedFile.discussions && selectedFile.discussions.length) {
        selectedFile.discussions = selectedFile.discussions.filter(
          discussion => discussion.notes.length,
        );
      }
    }
  },

  [types.TOGGLE_LINE_DISCUSSIONS](state, { fileHash, lineCode, expanded }) {
    const selectedFile = state.diffFiles.find(f => f.file_hash === fileHash);

    updateLineInFile(selectedFile, lineCode, line =>
      Object.assign(line, { discussionsExpanded: expanded }),
    );
  },

  [types.TOGGLE_FOLDER_OPEN](state, path) {
    state.treeEntries[path].opened = !state.treeEntries[path].opened;
  },
  [types.TOGGLE_SHOW_TREE_LIST](state) {
    state.showTreeList = !state.showTreeList;
  },
  [types.UPDATE_CURRENT_DIFF_FILE_ID](state, fileId) {
    state.currentDiffFileId = fileId;
  },
  [types.OPEN_DIFF_FILE_COMMENT_FORM](state, formData) {
    state.commentForms.push({
      ...formData,
    });
  },
  [types.UPDATE_DIFF_FILE_COMMENT_FORM](state, formData) {
    const { fileHash } = formData;

    state.commentForms = state.commentForms.map(form => {
      if (form.fileHash === fileHash) {
        return {
          ...formData,
        };
      }

      return form;
    });
  },
  [types.CLOSE_DIFF_FILE_COMMENT_FORM](state, fileHash) {
    state.commentForms = state.commentForms.filter(form => form.fileHash !== fileHash);
  },
  [types.SET_HIGHLIGHTED_ROW](state, lineCode) {
    state.highlightedRow = lineCode;
  },
  [types.SET_TREE_DATA](state, { treeEntries, tree }) {
    state.treeEntries = treeEntries;
    state.tree = tree;
  },
  [types.SET_RENDER_TREE_LIST](state, renderTreeList) {
    state.renderTreeList = renderTreeList;
  },
  [types.SET_SHOW_WHITESPACE](state, showWhitespace) {
    state.showWhitespace = showWhitespace;
  },
  [types.TOGGLE_FILE_FINDER_VISIBLE](state, visible) {
    state.fileFinderVisible = visible;
  },
  [types.REQUEST_FULL_DIFF](state, filePath) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = true;
  },
  [types.RECEIVE_FULL_DIFF_ERROR](state, filePath) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isLoadingFullFile = false;
  },
  [types.RECEIVE_FULL_DIFF_SUCCESS](state, { filePath }) {
    const file = findDiffFile(state.diffFiles, filePath, 'file_path');

    file.isShowingFullFile = true;
    file.isLoadingFullFile = false;
  },
  [types.SET_FILE_COLLAPSED](state, { filePath, collapsed }) {
    const file = state.diffFiles.find(f => f.file_path === filePath);

    if (file && file.viewer) {
      file.viewer.collapsed = collapsed;
    }
  },
  [types.SET_HIDDEN_VIEW_DIFF_FILE_LINES](state, { filePath, lines }) {
    const file = state.diffFiles.find(f => f.file_path === filePath);
    const hiddenDiffLinesKey =
      state.diffViewType === 'inline' ? 'parallel_diff_lines' : 'highlighted_diff_lines';

    file[hiddenDiffLinesKey] = lines;
  },
  [types.SET_CURRENT_VIEW_DIFF_FILE_LINES](state, { filePath, lines }) {
    const file = state.diffFiles.find(f => f.file_path === filePath);
    const currentDiffLinesKey =
      state.diffViewType === 'inline' ? 'highlighted_diff_lines' : 'parallel_diff_lines';

    file[currentDiffLinesKey] = lines;
  },
  [types.ADD_CURRENT_VIEW_DIFF_FILE_LINES](state, { filePath, line }) {
    const file = state.diffFiles.find(f => f.file_path === filePath);
    const currentDiffLinesKey =
      state.diffViewType === 'inline' ? 'highlighted_diff_lines' : 'parallel_diff_lines';

    file[currentDiffLinesKey].push(line);
  },
  [types.TOGGLE_DIFF_FILE_RENDERING_MORE](state, filePath) {
    const file = state.diffFiles.find(f => f.file_path === filePath);

    file.renderingLines = !file.renderingLines;
  },
  [types.SET_SHOW_SUGGEST_POPOVER](state) {
    state.showSuggestPopover = false;
  },
};
