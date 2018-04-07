import _ from 'underscore';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  MATCH_LINE_TYPE,
} from '../constants';

export function findDiffFile(files, hash) {
  return files.filter(file => file.fileHash === hash)[0];
}

export const getReversePosition = linePosition => {
  if (linePosition === LINE_POSITION_RIGHT) {
    return LINE_POSITION_LEFT;
  }

  return LINE_POSITION_RIGHT;
};

export const getNoteFormData = params => {
  const {
    note,
    noteableType,
    noteableData,
    diffFile,
    noteTargetLine,
    diffViewType,
    linePosition,
  } = params;

  // TODO: Discuss with @felipe_arthur to remove this JSON.stringify
  const position = JSON.stringify({
    base_sha: diffFile.diffRefs.baseSha,
    start_sha: diffFile.diffRefs.startSha,
    head_sha: diffFile.diffRefs.headSha,
    old_path: diffFile.oldPath,
    new_path: diffFile.newPath,
    position_type: TEXT_DIFF_POSITION_TYPE,
    old_line: noteTargetLine.oldLine,
    new_line: noteTargetLine.newLine,
  });

  // TODO: @fatihacet - Double check empty strings
  const postData = {
    view: diffViewType,
    line_type: linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
    merge_request_diff_head_sha: diffFile.diffRefs.headSha,
    in_reply_to_discussion_id: '',
    note_project_id: '',
    target_type: noteableType,
    target_id: noteableData.id,
    'note[noteable_type]': noteableType,
    'note[noteable_id]': noteableData.id,
    'note[commit_id]': '',
    'note[type]': DIFF_NOTE_TYPE,
    'note[line_code]': noteTargetLine.lineCode,
    'note[note]': note,
    'note[position]': position,
  };

  return {
    endpoint: noteableData.create_note_path,
    data: postData,
  };
};

export const findIndexInInlineLines = (lines, lineNumbers) => {
  const { oldLineNumber, newLineNumber } = lineNumbers;

  return _.findIndex(
    lines,
    line => line.oldLine === oldLineNumber && line.newLine === newLineNumber,
  );
};

export const findIndexInParallelLines = (lines, lineNumbers) => {
  const { oldLineNumber, newLineNumber } = lineNumbers;

  return _.findIndex(
    lines,
    line =>
      line.left &&
      line.right &&
      line.left.oldLine === oldLineNumber &&
      line.right.newLine === newLineNumber,
  );
};

export function removeMatchLine(diffFile, lineNumbers, bottom) {
  const indexForInline = findIndexInInlineLines(diffFile.highlightedDiffLines, lineNumbers);
  const indexForParallel = findIndexInParallelLines(diffFile.parallelDiffLines, lineNumbers);
  const factor = bottom ? 1 : -1;

  diffFile.highlightedDiffLines.splice(indexForInline + factor, 1);
  diffFile.parallelDiffLines.splice(indexForParallel + factor, 1);
}

export function addLineReferences(lines, lineNumbers, bottom) {
  const { oldLineNumber, newLineNumber } = lineNumbers;
  const lineCount = lines.length;
  let matchLineIndex = -1;

  const linesWithNumbers = lines.map((l, index) => {
    const line = convertObjectPropsToCamelCase(l);

    if (line.type === MATCH_LINE_TYPE) {
      matchLineIndex = index;
    } else {
      Object.assign(line, {
        oldLine: bottom ? oldLineNumber + index + 1 : oldLineNumber + index - lineCount,
        newLine: bottom ? newLineNumber + index + 1 : newLineNumber + index - lineCount,
      });
    }

    return line;
  });

  if (matchLineIndex > -1) {
    const line = linesWithNumbers[matchLineIndex];
    const targetLine = bottom
      ? linesWithNumbers[matchLineIndex - 1]
      : linesWithNumbers[matchLineIndex + 1];

    Object.assign(line, {
      metaData: {
        oldPos: targetLine.oldLine,
        newPos: targetLine.newLine,
      },
    });
  }

  return linesWithNumbers;
}

export function addContextLines(options) {
  const { inlineLines, parallelLines, contextLines, lineNumbers } = options;
  const normalizedParallelLines = contextLines.map(line => ({
    left: line,
    right: line,
  }));

  if (options.bottom) {
    inlineLines.push(...contextLines);
    parallelLines.push(...normalizedParallelLines);
  } else {
    const inlineIndex = findIndexInInlineLines(inlineLines, lineNumbers);
    const parallelIndex = findIndexInParallelLines(parallelLines, lineNumbers);
    inlineLines.splice(inlineIndex, 0, ...contextLines);
    parallelLines.splice(parallelIndex, 0, ...normalizedParallelLines);
  }
}
