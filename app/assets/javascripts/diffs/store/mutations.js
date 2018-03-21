import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as utils from './utils';
import * as types from './mutation_types';
import * as constants from '../constants';

export default {
  [types.SET_ENDPOINT](state, endpoint) {
    Object.assign(state, { endpoint });
  },

  [types.SET_LOADING](state, loadingState) {
    Object.assign(state, { isLoading: loadingState });
  },

  [types.SET_DIFF_FILES](state, diffFiles) {
    Object.assign(state, {
      diffFiles: convertObjectPropsToCamelCase(diffFiles, {
        deep: true,
      }),
    });
  },

  [types.SET_DIFF_VIEW_TYPE](state, type) {
    Object.assign(state, { diffViewType: type });
  },

  [types.ADD_COMMENT_FORM_LINE](state, { diffLines, lineCode, linePosition }) {
    const index = utils.findDiffLineIndex({
      diffLines,
      lineCode,
      linePosition,
    });
    const commentFormType = constants.COMMENT_FORM_TYPE;

    if (!diffLines[index]) {
      return;
    }

    const item = linePosition
      ? diffLines[index][linePosition]
      : diffLines[index];

    if (!item) {
      return;
    }

    // We add forms as another diff line so they have to have a unique id
    // We later use this id to remove the form from diff lines
    const id = `${item.lineCode}_CommentForm_${linePosition || ''}`;
    const targetIndex = index + 1;
    const targetLine = diffLines[targetIndex];
    const atTargetIndex = linePosition ? targetLine[linePosition] : targetLine;

    // We already have comment form for target line
    if (atTargetIndex && atTargetIndex.id === id) {
      return;
    }

    // Unique comment form object as a diff line
    const formObj = {
      id,
      type: commentFormType,
    };

    if (linePosition) {
      // linePosition is only valid for Parallel mode
      // Create the final lineObj which will represent the forms as a line
      // Restore old form in opposite position so we can rerender it
      const reversePosition = utils.getReversePosition(linePosition);
      const reverseObj = targetLine[reversePosition];
      const lineObj = {
        [linePosition]: formObj,
        [reversePosition]:
          reverseObj.type === commentFormType ? reverseObj : {},
      };

      // Check if there is any comment form on the target position
      // If we have, we should to remove it because above lineObj should be final version
      const { left, right } = targetLine;
      const hasAlreadyForm =
        left.type === commentFormType || right.type === commentFormType;
      const spliceCount = hasAlreadyForm ? 1 : 0;

      diffLines.splice(targetIndex, spliceCount, lineObj);
    } else {
      diffLines.splice(targetIndex, 0, formObj);
    }
  },

  [types.REMOVE_COMMENT_FORM_LINE](state, { diffLines, formId, linePosition }) {
    const index = utils.findDiffLineIndex({ diffLines, formId, linePosition });

    if (index > -1) {
      if (linePosition) {
        const reversePosition = utils.getReversePosition(linePosition);
        const line = diffLines[index];
        const reverse = line[reversePosition];
        const shouldRemove = reverse.type !== constants.COMMENT_FORM_TYPE;

        if (shouldRemove) {
          diffLines.splice(index, 1);
        } else {
          Object.assign(line, {
            [linePosition]: {},
          });
        }
      } else {
        diffLines.splice(index, 1);
      }
    }
  },

  [types.ADD_CONTEXT_LINES](state, options) {
    const { lineNumbers, contextLines, fileHash } = options;
    const { bottom } = options.params;
    const diffFile = utils.findDiffFile(state.diffFiles, fileHash);
    const { highlightedDiffLines, parallelDiffLines } = diffFile;

    utils.removeMatchLine(diffFile, lineNumbers, bottom);
    const lines = utils.addLineReferences(contextLines, lineNumbers, bottom);
    utils.addContextLines({
      inlineLines: highlightedDiffLines,
      parallelLines: parallelDiffLines,
      contextLines: lines,
      bottom,
      lineNumbers,
    });
  },
};
