import { property, isEqual } from 'lodash';
import { diffModes, diffViewerModes } from '~/ide/constants';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  LEGACY_DIFF_NOTE_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  MATCH_LINE_TYPE,
  LINES_TO_BE_RENDERED_DIRECTLY,
  INLINE_DIFF_LINES_KEY,
  CONFLICT_OUR,
  CONFLICT_THEIR,
  CONFLICT_MARKER,
  CONFLICT_MARKER_OUR,
  CONFLICT_MARKER_THEIR,
} from '../constants';
import { prepareRawDiffFile } from '../utils/diff_file';

export const isAdded = (line) => ['new', 'new-nonewline'].includes(line.type);
export const isRemoved = (line) => ['old', 'old-nonewline'].includes(line.type);
export const isUnchanged = (line) => !line.type;
export const isMeta = (line) => ['match', 'new-nonewline', 'old-nonewline'].includes(line.type);
export const isConflictMarker = (line) =>
  [CONFLICT_MARKER_OUR, CONFLICT_MARKER_THEIR].includes(line.type);
export const isConflictSeperator = (line) => line.type === CONFLICT_MARKER;
export const isConflictOur = (line) => line.type === CONFLICT_OUR;
export const isConflictTheir = (line) => line.type === CONFLICT_THEIR;

/**
 * Pass in the inline diff lines array which gets converted
 * to the parallel diff lines.
 * This allows for us to convert inline diff lines to parallel
 * on the frontend without needing to send any requests
 * to the API.
 *
 * This method has been taken from the already existing backend
 * implementation at lib/gitlab/diff/parallel_diff.rb
 *
 * @param {Object[]} diffLines - inline diff lines
 *
 * @param {Boolean} inline - is inline context or not
 *
 * @returns {Object[]} parallel lines
 */

export const parallelizeDiffLines = (diffLines, inline) => {
  let freeRightIndex = null;
  let conflictStartIndex = -1;
  const lines = [];

  // `chunk` is used for dragging to select diff lines
  // we are restricting commenting to only lines that appear between
  // "expansion rows". Here equal chunks are lines grouped together
  // inbetween expansion rows.
  let chunk = 0;

  for (let i = 0, diffLinesLength = diffLines.length, index = 0; i < diffLinesLength; i += 1) {
    const line = diffLines[i];
    line.chunk = chunk;

    if (isMeta(line)) chunk += 1;

    if (isRemoved(line) || isConflictOur(line) || inline) {
      lines.push({
        [LINE_POSITION_LEFT]: line,
        [LINE_POSITION_RIGHT]: null,
      });

      if (freeRightIndex === null) {
        // Once we come upon a new line it can be put on the right of this old line
        freeRightIndex = index;
      }
      index += 1;
    } else if (isAdded(line) || isConflictTheir(line)) {
      if (freeRightIndex !== null) {
        // If an old line came before this without a line on the right, this
        // line can be put to the right of it.
        lines[freeRightIndex].right = line;

        // If there are any other old lines on the left that don't yet have
        // a new counterpart on the right, update the free_right_index
        const nextFreeRightIndex = freeRightIndex + 1;
        freeRightIndex = nextFreeRightIndex < index ? nextFreeRightIndex : null;
      } else {
        lines.push({
          [LINE_POSITION_LEFT]: null,
          [LINE_POSITION_RIGHT]: line,
        });

        freeRightIndex = null;
        index += 1;
      }
    } else if (
      isMeta(line) ||
      isUnchanged(line) ||
      isConflictMarker(line) ||
      (isConflictSeperator(line) && inline)
    ) {
      if (conflictStartIndex <= 0) {
        // line in the right panel is the same as in the left one
        lines.push({
          [LINE_POSITION_LEFT]: line,
          [LINE_POSITION_RIGHT]: !inline && line,
        });

        if (!inline && isConflictMarker(line)) {
          conflictStartIndex = index;
        }
        freeRightIndex = null;
        index += 1;
      } else {
        lines[conflictStartIndex][LINE_POSITION_RIGHT] = line;
        conflictStartIndex = -1;
      }
    }
  }

  return lines;
};

export function findDiffFile(files, match, matchKey = 'file_hash') {
  return files.find((file) => file[matchKey] === match);
}

export const getReversePosition = (linePosition) => {
  if (linePosition === LINE_POSITION_RIGHT) {
    return LINE_POSITION_LEFT;
  }

  return LINE_POSITION_RIGHT;
};

export function getFormData(params) {
  const {
    commit,
    note,
    noteableType,
    noteableData,
    diffFile,
    noteTargetLine,
    diffViewType,
    linePosition,
    positionType,
    lineRange,
  } = params;

  const position = JSON.stringify({
    base_sha: diffFile.diff_refs.base_sha,
    start_sha: diffFile.diff_refs.start_sha,
    head_sha: diffFile.diff_refs.head_sha,
    old_path: diffFile.old_path,
    new_path: diffFile.new_path,
    position_type: positionType || TEXT_DIFF_POSITION_TYPE,
    old_line: noteTargetLine ? noteTargetLine.old_line : null,
    new_line: noteTargetLine ? noteTargetLine.new_line : null,
    x: params.x,
    y: params.y,
    width: params.width,
    height: params.height,
    line_range: lineRange,
  });

  const postData = {
    view: diffViewType,
    line_type: linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
    merge_request_diff_head_sha: diffFile.diff_refs.head_sha,
    in_reply_to_discussion_id: '',
    note_project_id: '',
    target_type: noteableData.targetType,
    target_id: noteableData.id,
    return_discussion: true,
    note: {
      note,
      position,
      noteable_type: noteableType,
      noteable_id: noteableData.id,
      commit_id: commit && commit.id,
      type:
        diffFile.diff_refs.start_sha && diffFile.diff_refs.head_sha
          ? DIFF_NOTE_TYPE
          : LEGACY_DIFF_NOTE_TYPE,
      line_code: noteTargetLine ? noteTargetLine.line_code : null,
    },
  };

  return postData;
}

export function getNoteFormData(params) {
  const data = getFormData(params);

  return {
    endpoint: params.noteableData.create_note_path,
    data,
  };
}

export const findIndexInInlineLines = (lines, lineNumbers) => {
  const { oldLineNumber, newLineNumber } = lineNumbers;

  return lines.findIndex(
    (line) => line.old_line === oldLineNumber && line.new_line === newLineNumber,
  );
};

export const getPreviousLineIndex = (diffViewType, file, lineNumbers) => {
  return findIndexInInlineLines(file[INLINE_DIFF_LINES_KEY], lineNumbers);
};

export function removeMatchLine(diffFile, lineNumbers, bottom) {
  const indexForInline = findIndexInInlineLines(diffFile[INLINE_DIFF_LINES_KEY], lineNumbers);
  const factor = bottom ? 1 : -1;

  if (indexForInline > -1) {
    diffFile[INLINE_DIFF_LINES_KEY].splice(indexForInline + factor, 1);
  }
}

export function addLineReferences(lines, lineNumbers, bottom, isExpandDown, nextLineNumbers) {
  const { oldLineNumber, newLineNumber } = lineNumbers;
  const lineCount = lines.length;
  let matchLineIndex = -1;

  const linesWithNumbers = lines.map((l, index) => {
    if (l.type === MATCH_LINE_TYPE) {
      matchLineIndex = index;
    } else {
      Object.assign(l, {
        old_line: bottom ? oldLineNumber + index + 1 : oldLineNumber + index - lineCount,
        new_line: bottom ? newLineNumber + index + 1 : newLineNumber + index - lineCount,
      });
    }
    return l;
  });

  if (matchLineIndex > -1) {
    const line = linesWithNumbers[matchLineIndex];
    let targetLine;

    if (isExpandDown) {
      targetLine = nextLineNumbers;
    } else if (bottom) {
      targetLine = linesWithNumbers[matchLineIndex - 1];
    } else {
      targetLine = linesWithNumbers[matchLineIndex + 1];
    }

    Object.assign(line, {
      meta_data: {
        old_pos: targetLine.old_line,
        new_pos: targetLine.new_line,
      },
    });
  }
  return linesWithNumbers;
}

function addInlineContextLines(options) {
  const { inlineLines, contextLines, lineNumbers, isExpandDown } = options;
  const factor = isExpandDown ? 1 : 0;

  if (!isExpandDown && options.bottom) {
    inlineLines.push(...contextLines);
  } else {
    const inlineIndex = findIndexInInlineLines(inlineLines, lineNumbers);

    inlineLines.splice(inlineIndex + factor, 0, ...contextLines);
  }
}

export function addContextLines(options) {
  addInlineContextLines(options);
}

/**
 * Trims the first char of the `richText` property when it's either a space or a diff symbol.
 * @param {Object} line
 * @returns {Object}
 * @deprecated Use `line.rich_text = line.rich_text ? line.rich_text.replace(/^[+ -]/, '') : undefined;` instead!. For more information, see https://gitlab.com/gitlab-org/gitlab/-/issues/299329
 */
export function trimFirstCharOfLineContent(line = {}) {
  // eslint-disable-next-line no-param-reassign
  delete line.text;

  const parsedLine = { ...line };

  if (line.rich_text) {
    const firstChar = parsedLine.rich_text.charAt(0);

    if (firstChar === ' ' || firstChar === '+' || firstChar === '-') {
      parsedLine.rich_text = line.rich_text.substring(1);
    }
  }

  return parsedLine;
}

function diffFileUniqueId(file) {
  return `${file.content_sha}-${file.file_hash}`;
}

function mergeTwoFiles(target, source) {
  const originalInline = target[INLINE_DIFF_LINES_KEY];
  const missingInline = !originalInline.length;

  return {
    ...target,
    [INLINE_DIFF_LINES_KEY]: missingInline ? source[INLINE_DIFF_LINES_KEY] : originalInline,
    parallel_diff_lines: null,
    renderIt: source.renderIt,
    collapsed: source.collapsed,
  };
}

function ensureBasicDiffFileLines(file) {
  const missingInline = !file[INLINE_DIFF_LINES_KEY];

  Object.assign(file, {
    [INLINE_DIFF_LINES_KEY]: missingInline ? [] : file[INLINE_DIFF_LINES_KEY],
    parallel_diff_lines: null,
  });

  return file;
}

function cleanRichText(text) {
  return text ? text.replace(/^[+ -]/, '') : undefined;
}

function prepareLine(line, file) {
  if (!line.alreadyPrepared) {
    Object.assign(line, {
      commentsDisabled: file.brokenSymlink,
      rich_text: cleanRichText(line.rich_text),
      discussionsExpanded: true,
      discussions: [],
      hasForm: false,
      text: undefined,
      alreadyPrepared: true,
    });
  }
}

export function prepareLineForRenamedFile({ line, diffFile, index = 0 }) {
  /*
    Renamed files are a little different than other diffs, which
    is why this is distinct from `prepareDiffFileLines` below.

    We don't get any of the diff file context when we get the diff
    (so no "inline" vs. "parallel", no "line_code", etc.).

    We can also assume that both the left and the right of each line
    (for parallel diff view type) are identical, because the file
    is renamed, not modified.

    This should be cleaned up as part of the effort around flattening our data
    ==> https://gitlab.com/groups/gitlab-org/-/epics/2852#note_304803402
  */
  const lineNumber = index + 1;
  const cleanLine = {
    ...line,
    line_code: `${diffFile.file_hash}_${lineNumber}_${lineNumber}`,
    new_line: lineNumber,
    old_line: lineNumber,
  };

  prepareLine(cleanLine, diffFile); // WARNING: In-Place Mutations!

  return cleanLine;
}

function prepareDiffFileLines(file) {
  const inlineLines = file[INLINE_DIFF_LINES_KEY];

  inlineLines.forEach((line) => prepareLine(line, file)); // WARNING: In-Place Mutations!

  return file;
}

function finalizeDiffFile(file, index) {
  let renderIt = Boolean(window.gon?.features?.diffsVirtualScrolling);

  if (!window.gon?.features?.diffsVirtualScrolling) {
    renderIt =
      index < 3 ? file[INLINE_DIFF_LINES_KEY].length < LINES_TO_BE_RENDERED_DIRECTLY : false;
  }

  Object.assign(file, {
    renderIt,
    isShowingFullFile: false,
    isLoadingFullFile: false,
    discussions: [],
    renderingLines: false,
  });

  return file;
}

function deduplicateFilesList(files) {
  const dedupedFiles = files.reduce((newList, file) => {
    const id = diffFileUniqueId(file);

    return {
      ...newList,
      [id]: newList[id] ? mergeTwoFiles(newList[id], file) : file,
    };
  }, {});

  return Object.values(dedupedFiles);
}

export function prepareDiffData({ diff, priorFiles = [], meta = false }) {
  const cleanedFiles = (diff.diff_files || [])
    .map((file, index, allFiles) => prepareRawDiffFile({ file, allFiles, meta }))
    .map(ensureBasicDiffFileLines)
    .map(prepareDiffFileLines)
    .map((file, index) => finalizeDiffFile(file, priorFiles.length + index));

  return deduplicateFilesList([...priorFiles, ...cleanedFiles]);
}

export function getDiffPositionByLineCode(diffFiles) {
  let lines = [];

  lines = diffFiles.reduce((acc, diffFile) => {
    diffFile[INLINE_DIFF_LINES_KEY].forEach((line) => {
      acc.push({ file: diffFile, line });
    });

    return acc;
  }, []);

  return lines.reduce((acc, { file, line }) => {
    if (line.line_code) {
      acc[line.line_code] = {
        base_sha: file.diff_refs.base_sha,
        head_sha: file.diff_refs.head_sha,
        start_sha: file.diff_refs.start_sha,
        new_path: file.new_path,
        old_path: file.old_path,
        old_line: line.old_line,
        new_line: line.new_line,
        line_range: null,
        line_code: line.line_code,
        position_type: 'text',
      };
    }

    return acc;
  }, {});
}

// This method will check whether the discussion is still applicable
// to the diff line in question regarding different versions of the MR
export function isDiscussionApplicableToLine({ discussion, diffPosition, latestDiff }) {
  if (!diffPosition) {
    return false;
  }

  const { line_code, ...dp } = diffPosition;
  // Removing `line_range` from diffPosition because the backend does not
  // yet consistently return this property. This check can be removed,
  // once this is addressed. see https://gitlab.com/gitlab-org/gitlab/-/issues/213010
  const { line_range: dpNotUsed, ...diffPositionCopy } = dp;

  if (discussion.original_position && discussion.position) {
    const discussionPositions = [
      discussion.original_position,
      discussion.position,
      ...(discussion.positions || []),
    ];

    const removeLineRange = (position) => {
      const { line_range: pNotUsed, ...positionNoLineRange } = position;
      return positionNoLineRange;
    };

    return discussionPositions
      .map(removeLineRange)
      .some((position) => isEqual(position, diffPositionCopy));
  }

  // eslint-disable-next-line
  return latestDiff && discussion.active && line_code === discussion.line_code;
}

export const getDiffMode = (diffFile) => {
  const diffModeKey = Object.keys(diffModes).find((key) => diffFile[`${key}_file`]);
  return (
    diffModes[diffModeKey] ||
    (diffFile.viewer &&
      diffFile.viewer.name === diffViewerModes.mode_changed &&
      diffViewerModes.mode_changed) ||
    diffModes.replaced
  );
};

export const convertExpandLines = ({
  diffLines,
  data,
  typeKey,
  oldLineKey,
  newLineKey,
  mapLine,
}) => {
  const dataLength = data.length;
  const lines = [];

  for (let i = 0, diffLinesLength = diffLines.length; i < diffLinesLength; i += 1) {
    const line = diffLines[i];

    if (property(typeKey)(line) === 'match') {
      const beforeLine = diffLines[i - 1];
      const afterLine = diffLines[i + 1];
      const newLineProperty = property(newLineKey);
      const beforeLineIndex = newLineProperty(beforeLine) || 0;
      const afterLineIndex = newLineProperty(afterLine) - 1 || dataLength;

      lines.push(
        ...data.slice(beforeLineIndex, afterLineIndex).map((l, index) =>
          mapLine({
            line: Object.assign(l, { hasForm: false, discussions: [] }),
            oldLine: (property(oldLineKey)(beforeLine) || 0) + index + 1,
            newLine: (newLineProperty(beforeLine) || 0) + index + 1,
          }),
        ),
      );
    } else {
      lines.push(line);
    }
  }

  return lines;
};

export const idleCallback = (cb) => requestIdleCallback(cb);

function getLinesFromFileByLineCode(file, lineCode) {
  const inlineLines = file[INLINE_DIFF_LINES_KEY];
  const matchesCode = (line) => line.line_code === lineCode;

  return inlineLines.filter(matchesCode);
}

export const updateLineInFile = (selectedFile, lineCode, updateFn) => {
  getLinesFromFileByLineCode(selectedFile, lineCode).forEach(updateFn);
};

export const allDiscussionWrappersExpanded = (diff) => {
  let discussionsExpanded = true;
  const changeExpandedResult = (line) => {
    if (line && line.discussions.length) {
      discussionsExpanded = discussionsExpanded && line.discussionsExpanded;
    }
  };

  diff[INLINE_DIFF_LINES_KEY].forEach((line) => {
    changeExpandedResult(line);
  });

  return discussionsExpanded;
};
