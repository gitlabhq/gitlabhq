import { truncate, truncateSha } from '~/lib/utils/text_utility';
import {
  createOriginHeaderText,
  createHeadHeaderText,
  ORIGIN_BUTTON_TITLE,
  HEAD_BUTTON_TITLE,
  DEFAULT_RESOLVE_MODE,
  CONFLICT_TYPES,
} from './constants';

export const getFilePath = (file) => {
  const { old_path, new_path } = file;
  // eslint-disable-next-line camelcase
  return old_path === new_path ? new_path : `${old_path} → ${new_path}`;
};

export const checkLineLengths = ({ left, right }) => {
  const wLeft = [...left];
  const wRight = [...right];
  if (left.length !== right.length) {
    if (left.length > right.length) {
      const diff = left.length - right.length;
      for (let i = 0; i < diff; i += 1) {
        wRight.push({ lineType: 'emptyLine', richText: '' });
      }
    } else {
      const diff = right.length - left.length;
      for (let i = 0; i < diff; i += 1) {
        wLeft.push({ lineType: 'emptyLine', richText: '' });
      }
    }
  }
  return { left: wLeft, right: wRight };
};

export const getHeadHeaderLine = (id, data) => {
  const commit = truncateSha(data.source_commit.sha);
  const message = truncate(data.source_commit.message.split('\n')[0], 50);
  return {
    id,
    richText: createHeadHeaderText({ commit, message }),
    buttonTitle: HEAD_BUTTON_TITLE,
    type: 'new',
    section: 'head',
    isHeader: true,
    isHead: true,
    isSelected: false,
    isUnselected: false,
  };
};

export const decorateLineForInlineView = (line, id, conflict) => {
  const { type } = line;
  return {
    id,
    hasConflict: conflict,
    isHead: type === 'new',
    isOrigin: type === 'old',
    hasMatch: type === 'match',
    richText: line.rich_text,
    isSelected: false,
    isUnselected: false,
  };
};

// eslint-disable-next-line max-params
export const getLineForParallelView = (line, id, lineType, isHead) => {
  const { old_line: oldLine, new_line: newLine, rich_text: richText } = line;
  const hasConflict = lineType === 'conflict';

  return {
    id,
    lineType,
    hasConflict,
    isHead: hasConflict && isHead,
    isOrigin: hasConflict && !isHead,
    hasMatch: lineType === 'match',
    lineNumber: isHead ? newLine : oldLine,
    section: isHead ? 'head' : 'origin',
    richText,
    isSelected: false,
    isUnselected: false,
  };
};

export const getOriginHeaderLine = (id, data) => {
  const target = truncate(data.target_branch, 50);
  return {
    id,
    richText: createOriginHeaderText({ target }),
    buttonTitle: ORIGIN_BUTTON_TITLE,
    type: 'old',
    section: 'origin',
    isHeader: true,
    isOrigin: true,
    isSelected: false,
    isUnselected: false,
  };
};

export const setInlineLine = (file, data) => {
  const inlineLines = [];

  file.sections.forEach((section) => {
    let currentLineType = 'new';
    const { conflict, lines, id } = section;

    if (conflict) {
      inlineLines.push(getHeadHeaderLine(id, data));
    }

    lines.forEach((line) => {
      const { type } = line;

      if ((type === 'new' || type === 'old') && currentLineType !== type) {
        currentLineType = type;
        inlineLines.push({ lineType: 'emptyLine', richText: '' });
      }

      const decoratedLine = decorateLineForInlineView(line, id, conflict);
      inlineLines.push(decoratedLine);
    });

    if (conflict) {
      inlineLines.push(getOriginHeaderLine(id, data));
    }
  });

  return inlineLines;
};

export const setParallelLine = (file, data) => {
  const parallelLines = [];
  let linesObj = { left: [], right: [] };

  file.sections.forEach((section) => {
    const { conflict, lines, id } = section;

    if (conflict) {
      linesObj.left.push(getOriginHeaderLine(id, data));
      linesObj.right.push(getHeadHeaderLine(id, data));
    }

    lines.forEach((line) => {
      const { type } = line;

      if (conflict) {
        if (type === 'old') {
          linesObj.left.push(getLineForParallelView(line, id, 'conflict'));
        } else if (type === 'new') {
          linesObj.right.push(getLineForParallelView(line, id, 'conflict', true));
        }
      } else {
        const lineType = type || 'context';

        linesObj.left.push(getLineForParallelView(line, id, lineType));
        linesObj.right.push(getLineForParallelView(line, id, lineType, true));
      }
    });

    linesObj = checkLineLengths(linesObj);
  });

  for (let i = 0, len = linesObj.left.length; i < len; i += 1) {
    parallelLines.push([linesObj.right[i], linesObj.left[i]]);
  }
  return parallelLines;
};

export const decorateFiles = (data) => {
  return data.files.map((file) => {
    const f = { ...file };
    f.content = '';
    f.resolutionData = {};
    f.promptDiscardConfirmation = false;
    f.resolveMode = DEFAULT_RESOLVE_MODE;
    f.filePath = getFilePath(file);
    f.blobPath = f.blob_path;

    if (f.type === CONFLICT_TYPES.TEXT) {
      f.showEditor = false;
      f.loadEditor = false;

      f.inlineLines = setInlineLine(file, data);
      f.parallelLines = setParallelLine(file, data);
    } else if (f.type === CONFLICT_TYPES.TEXT_EDITOR) {
      f.showEditor = true;
      f.loadEditor = true;
    }
    return f;
  });
};

export const restoreFileLinesState = (file) => {
  const inlineLines = file.inlineLines.map((line) => {
    if (line.hasConflict || line.isHeader) {
      return { ...line, isSelected: false, isUnselected: false };
    }
    return { ...line };
  });

  const parallelLines = file.parallelLines.map((lines) => {
    const left = { ...lines[0] };
    const right = { ...lines[1] };
    const isLeftMatch = left.hasConflict || left.isHeader;
    const isRightMatch = right.hasConflict || right.isHeader;

    if (isLeftMatch || isRightMatch) {
      left.isSelected = false;
      left.isUnselected = false;
      right.isSelected = false;
      right.isUnselected = false;
    }
    return [left, right];
  });
  return { inlineLines, parallelLines };
};

export const markLine = (line, selection) => {
  const updated = { ...line };
  if (selection === 'head' && line.isHead) {
    updated.isSelected = true;
    updated.isUnselected = false;
  } else if (selection === 'origin' && updated.isOrigin) {
    updated.isSelected = true;
    updated.isUnselected = false;
  } else {
    updated.isSelected = false;
    updated.isUnselected = true;
  }
  return updated;
};
