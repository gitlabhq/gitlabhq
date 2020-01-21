import _ from 'underscore';
import { truncatePathMiddleToLength } from '~/lib/utils/text_utility';
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
  MAX_LINES_TO_BE_RENDERED,
  TREE_TYPE,
} from '../constants';

export function findDiffFile(files, match, matchKey = 'file_hash') {
  return files.find(file => file[matchKey] === match);
}

export const getReversePosition = linePosition => {
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

  return _.findIndex(
    lines,
    line => line.old_line === oldLineNumber && line.new_line === newLineNumber,
  );
};

export const findIndexInParallelLines = (lines, lineNumbers) => {
  const { oldLineNumber, newLineNumber } = lineNumbers;

  return _.findIndex(
    lines,
    line =>
      line.left &&
      line.right &&
      line.left.old_line === oldLineNumber &&
      line.right.new_line === newLineNumber,
  );
};

export function removeMatchLine(diffFile, lineNumbers, bottom) {
  const indexForInline = findIndexInInlineLines(diffFile.highlighted_diff_lines, lineNumbers);
  const indexForParallel = findIndexInParallelLines(diffFile.parallel_diff_lines, lineNumbers);
  const factor = bottom ? 1 : -1;

  diffFile.highlighted_diff_lines.splice(indexForInline + factor, 1);
  diffFile.parallel_diff_lines.splice(indexForParallel + factor, 1);
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

export function addContextLines(options) {
  const { inlineLines, parallelLines, contextLines, lineNumbers, isExpandDown } = options;
  const normalizedParallelLines = contextLines.map(line => ({
    left: line,
    right: line,
    line_code: line.line_code,
  }));
  const factor = isExpandDown ? 1 : 0;

  if (!isExpandDown && options.bottom) {
    inlineLines.push(...contextLines);
    parallelLines.push(...normalizedParallelLines);
  } else {
    const inlineIndex = findIndexInInlineLines(inlineLines, lineNumbers);
    const parallelIndex = findIndexInParallelLines(parallelLines, lineNumbers);

    inlineLines.splice(inlineIndex + factor, 0, ...contextLines);
    parallelLines.splice(parallelIndex + factor, 0, ...normalizedParallelLines);
  }
}

/**
 * Trims the first char of the `richText` property when it's either a space or a diff symbol.
 * @param {Object} line
 * @returns {Object}
 * @deprecated
 */
export function trimFirstCharOfLineContent(line = {}) {
  // eslint-disable-next-line no-param-reassign
  delete line.text;

  const parsedLine = Object.assign({}, line);

  if (line.rich_text) {
    const firstChar = parsedLine.rich_text.charAt(0);

    if (firstChar === ' ' || firstChar === '+' || firstChar === '-') {
      parsedLine.rich_text = line.rich_text.substring(1);
    }
  }

  return parsedLine;
}

function getLineCode({ left, right }, index) {
  if (left && left.line_code) {
    return left.line_code;
  } else if (right && right.line_code) {
    return right.line_code;
  }
  return index;
}

function diffFileUniqueId(file) {
  return `${file.content_sha}-${file.file_hash}`;
}

function combineDiffFilesWithPriorFiles(files, prior = []) {
  files.forEach(file => {
    const id = diffFileUniqueId(file);
    const oldMatch = prior.find(oldFile => diffFileUniqueId(oldFile) === id);

    if (oldMatch) {
      const missingInline = !file.highlighted_diff_lines;
      const missingParallel = !file.parallel_diff_lines;

      if (missingInline) {
        Object.assign(file, {
          highlighted_diff_lines: oldMatch.highlighted_diff_lines,
        });
      }

      if (missingParallel) {
        Object.assign(file, {
          parallel_diff_lines: oldMatch.parallel_diff_lines,
        });
      }
    }
  });

  return files;
}

function ensureBasicDiffFileLines(file) {
  const missingInline = !file.highlighted_diff_lines;
  const missingParallel = !file.parallel_diff_lines;

  Object.assign(file, {
    highlighted_diff_lines: missingInline ? [] : file.highlighted_diff_lines,
    parallel_diff_lines: missingParallel ? [] : file.parallel_diff_lines,
  });

  return file;
}

function cleanRichText(text) {
  return text ? text.replace(/^[+ -]/, '') : undefined;
}

function prepareLine(line) {
  return Object.assign(line, {
    rich_text: cleanRichText(line.rich_text),
    discussionsExpanded: true,
    discussions: [],
    hasForm: false,
    text: undefined,
  });
}

function prepareDiffFileLines(file) {
  const inlineLines = file.highlighted_diff_lines;
  const parallelLines = file.parallel_diff_lines;
  let parallelLinesCount = 0;

  inlineLines.forEach(prepareLine);

  parallelLines.forEach((line, index) => {
    Object.assign(line, { line_code: getLineCode(line, index) });

    if (line.left) {
      parallelLinesCount += 1;
      prepareLine(line.left);
    }

    if (line.right) {
      parallelLinesCount += 1;
      prepareLine(line.right);
    }

    Object.assign(file, {
      inlineLinesCount: inlineLines.length,
      parallelLinesCount,
    });
  });

  return file;
}

function getVisibleDiffLines(file) {
  return Math.max(file.inlineLinesCount, file.parallelLinesCount);
}

function finalizeDiffFile(file) {
  const name = (file.viewer && file.viewer.name) || diffViewerModes.text;
  const lines = getVisibleDiffLines(file);

  Object.assign(file, {
    renderIt: lines < LINES_TO_BE_RENDERED_DIRECTLY,
    collapsed: name === diffViewerModes.text && lines > MAX_LINES_TO_BE_RENDERED,
    isShowingFullFile: false,
    isLoadingFullFile: false,
    discussions: [],
    renderingLines: false,
  });

  return file;
}

export function prepareDiffData(diffData, priorFiles) {
  return combineDiffFilesWithPriorFiles(diffData.diff_files, priorFiles)
    .map(ensureBasicDiffFileLines)
    .map(prepareDiffFileLines)
    .map(finalizeDiffFile);
}

export function getDiffPositionByLineCode(diffFiles, useSingleDiffStyle) {
  let lines = [];
  const hasInlineDiffs = diffFiles.some(file => file.highlighted_diff_lines.length > 0);

  if (!useSingleDiffStyle || hasInlineDiffs) {
    // In either of these cases, we can use `highlighted_diff_lines` because
    // that will include all of the parallel diff lines, too

    lines = diffFiles.reduce((acc, diffFile) => {
      diffFile.highlighted_diff_lines.forEach(line => {
        acc.push({ file: diffFile, line });
      });

      return acc;
    }, []);
  } else {
    // If we're in single diff view mode and the inline lines haven't been
    // loaded yet, we need to parse the parallel lines

    lines = diffFiles.reduce((acc, diffFile) => {
      diffFile.parallel_diff_lines.forEach(pair => {
        // It's possible for a parallel line to have an opposite line that doesn't exist
        // For example: *deleted* lines will have `null` right lines, while
        // *added* lines will have `null` left lines.
        // So we have to check each line before we push it onto the array so we're not
        // pushing null line diffs

        if (pair.left) {
          acc.push({ file: diffFile, line: pair.left });
        }

        if (pair.right) {
          acc.push({ file: diffFile, line: pair.right });
        }
      });

      return acc;
    }, []);
  }

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
  const { line_code, ...diffPositionCopy } = diffPosition;

  if (discussion.original_position && discussion.position) {
    const originalRefs = discussion.original_position;
    const refs = discussion.position;

    return _.isEqual(refs, diffPositionCopy) || _.isEqual(originalRefs, diffPositionCopy);
  }

  // eslint-disable-next-line
  return latestDiff && discussion.active && line_code === discussion.line_code;
}

export const getLowestSingleFolder = folder => {
  const getFolder = (blob, start = []) =>
    blob.tree.reduce(
      (acc, file) => {
        const shouldGetFolder = file.tree.length === 1 && file.tree[0].type === TREE_TYPE;
        const currentFileTypeTree = file.type === TREE_TYPE;
        const path = shouldGetFolder || currentFileTypeTree ? acc.path.concat(file.name) : acc.path;
        const tree = shouldGetFolder || currentFileTypeTree ? acc.tree.concat(file) : acc.tree;

        if (shouldGetFolder) {
          const firstFolder = getFolder(file);

          path.push(...firstFolder.path);
          tree.push(...firstFolder.tree);
        }

        return {
          ...acc,
          path,
          tree,
        };
      },
      { path: start, tree: [] },
    );
  const { path, tree } = getFolder(folder, [folder.name]);

  return {
    path: truncatePathMiddleToLength(path.join('/'), 40),
    treeAcc: tree.length ? tree[tree.length - 1].tree : null,
  };
};

export const flattenTree = tree => {
  const flatten = blobTree =>
    blobTree.reduce((acc, file) => {
      const blob = file;
      let treeToFlatten = blob.tree;

      if (file.type === TREE_TYPE && file.tree.length === 1) {
        const { treeAcc, path } = getLowestSingleFolder(file);

        if (treeAcc) {
          blob.name = path;
          treeToFlatten = flatten(treeAcc);
        }
      }

      blob.tree = flatten(treeToFlatten);

      return acc.concat(blob);
    }, []);

  return flatten(tree);
};

export const generateTreeList = files => {
  const { treeEntries, tree } = files.reduce(
    (acc, file) => {
      const split = file.new_path.split('/');

      split.forEach((name, i) => {
        const parent = acc.treeEntries[split.slice(0, i).join('/')];
        const path = `${parent ? `${parent.path}/` : ''}${name}`;

        if (!acc.treeEntries[path]) {
          const type = path === file.new_path ? 'blob' : 'tree';
          acc.treeEntries[path] = {
            key: path,
            path,
            name,
            type,
            tree: [],
          };

          const entry = acc.treeEntries[path];

          if (type === 'blob') {
            Object.assign(entry, {
              changed: true,
              tempFile: file.new_file,
              deleted: file.deleted_file,
              fileHash: file.file_hash,
              addedLines: file.added_lines,
              removedLines: file.removed_lines,
              parentPath: parent ? `${parent.path}/` : '/',
            });
          } else {
            Object.assign(entry, {
              opened: true,
            });
          }

          (parent ? parent.tree : acc.tree).push(entry);
        }
      });

      return acc;
    },
    { treeEntries: {}, tree: [] },
  );

  return { treeEntries, tree: flattenTree(tree) };
};

export const getDiffMode = diffFile => {
  const diffModeKey = Object.keys(diffModes).find(key => diffFile[`${key}_file`]);
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

    if (_.property(typeKey)(line) === 'match') {
      const beforeLine = diffLines[i - 1];
      const afterLine = diffLines[i + 1];
      const newLineProperty = _.property(newLineKey);
      const beforeLineIndex = newLineProperty(beforeLine) || 0;
      const afterLineIndex = newLineProperty(afterLine) - 1 || dataLength;

      lines.push(
        ...data.slice(beforeLineIndex, afterLineIndex).map((l, index) =>
          mapLine({
            line: Object.assign(l, { hasForm: false, discussions: [] }),
            oldLine: (_.property(oldLineKey)(beforeLine) || 0) + index + 1,
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

export const idleCallback = cb => requestIdleCallback(cb);

function getLinesFromFileByLineCode(file, lineCode) {
  const parallelLines = file.parallel_diff_lines;
  const inlineLines = file.highlighted_diff_lines;
  const matchesCode = line => line.line_code === lineCode;

  return [
    ...parallelLines.reduce((acc, line) => {
      if (line.left) {
        acc.push(line.left);
      }

      if (line.right) {
        acc.push(line.right);
      }

      return acc;
    }, []),
    ...inlineLines,
  ].filter(matchesCode);
}

export const updateLineInFile = (selectedFile, lineCode, updateFn) => {
  getLinesFromFileByLineCode(selectedFile, lineCode).forEach(updateFn);
};

export const allDiscussionWrappersExpanded = diff => {
  let discussionsExpanded = true;
  const changeExpandedResult = line => {
    if (line && line.discussions.length) {
      discussionsExpanded = discussionsExpanded && line.discussionsExpanded;
    }
  };

  diff.parallel_diff_lines.forEach(line => {
    changeExpandedResult(line.left);
    changeExpandedResult(line.right);
  });

  diff.highlighted_diff_lines.forEach(line => {
    changeExpandedResult(line);
  });

  return discussionsExpanded;
};
