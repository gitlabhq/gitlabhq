import { __ } from '~/locale';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
  CONFLICT_MARKER_OUR,
  CONFLICT_MARKER_THEIR,
  CONFLICT_THEIR,
  CONFLICT_OUR,
  EXPANDED_LINE_TYPE,
} from '../constants';

export const isHighlighted = (highlightedRow, line, isCommented) => {
  if (isCommented) return true;

  const lineCode = line?.line_code;
  return lineCode ? lineCode === highlightedRow : false;
};

export const isContextLine = (type) => type === CONTEXT_LINE_TYPE;

export const isMatchLine = (type) => type === MATCH_LINE_TYPE;

export const isMetaLine = (type) =>
  [OLD_NO_NEW_LINE_TYPE, NEW_NO_NEW_LINE_TYPE, EMPTY_CELL_TYPE].includes(type);

export const shouldRenderCommentButton = (isLoggedIn, isCommentButtonRendered) => {
  return isCommentButtonRendered && isLoggedIn;
};

export const hasDiscussions = (line) => line?.discussions?.length > 0;

export const fileContentsId = (diffFile) => {
  return `diff-content-${diffFile.file_hash}`;
};

const createDiffUrl = (diffFile) => {
  const url = new URL(window.location);
  url.searchParams.set('file', diffFile.file_hash);
  return url;
};

export const createFileUrl = (diffFile) => {
  const url = createDiffUrl(diffFile);
  url.hash = fileContentsId(diffFile);
  return url;
};

export const lineHref = (line, diffFile) => {
  if (!line || !line.line_code) return '';
  const url = createDiffUrl(diffFile);
  url.hash = line.line_code;
  return url.toString();
};

export const lineCode = (line) => {
  if (!line) return undefined;
  return line.line_code || line.left?.line_code || line.right?.line_code;
};

export const classNameMapCell = ({
  line,
  highlighted,
  commented,
  selectionStart,
  selectionEnd,
  isLoggedIn,
  isHover,
}) => {
  const classes = {
    'highlight-top': highlighted || selectionStart,
    'highlight-bottom': highlighted || selectionEnd,
    hll: highlighted,
    commented,
  };

  if (line) {
    const { type } = line;
    Object.assign(classes, {
      [type]: true,
      [LINE_HOVER_CLASS_NAME]: isLoggedIn && isHover && !isContextLine(type) && !isMetaLine(type),
      old_line: type === 'old',
      new_line: type === 'new',
    });
  }

  return [classes];
};

export const addCommentTooltip = (line) => {
  let tooltip;
  if (!line) {
    return tooltip;
  }

  tooltip = __('Add a comment to this line or drag for multiple lines');

  if (!line.problems) {
    return tooltip;
  }

  const { brokenSymlink, brokenLineCode, fileOnlyMoved } = line.problems;

  if (brokenSymlink) {
    if (brokenSymlink.wasSymbolic || brokenSymlink.isSymbolic) {
      tooltip = __(
        'Commenting on symbolic links that replace or are replaced by files is not supported',
      );
    } else if (brokenSymlink.wasReal || brokenSymlink.isReal) {
      tooltip = __(
        'Commenting on files that replace or are replaced by symbolic links is not supported',
      );
    }
  } else if (fileOnlyMoved) {
    tooltip = __('Commenting on files that are only moved or renamed is not supported');
  } else if (brokenLineCode) {
    tooltip = __('Commenting on this line is not supported');
  }

  return tooltip;
};

export const parallelViewLeftLineType = ({
  line,
  highlighted,
  commented,
  selectionStart,
  selectionEnd,
}) => {
  if (line?.right?.type === NEW_NO_NEW_LINE_TYPE) {
    return OLD_NO_NEW_LINE_TYPE;
  }

  const lineTypeClass = line?.left ? line.left.type : EMPTY_CELL_TYPE;

  return [
    lineTypeClass,
    {
      hll: highlighted,
      commented,
      'highlight-top': highlighted || selectionStart,
      'highlight-bottom': highlighted || selectionEnd,
    },
  ];
};

// eslint-disable-next-line max-params
export const shouldShowCommentButton = (hover, context, meta, discussions) => {
  return hover && !context && !meta && !discussions;
};

export const mapParallel =
  ({ diffFile, hasParallelDraftLeft, hasParallelDraftRight, draftsForLine }) =>
  (line) => {
    let { left, right } = line;

    // Dicussions/Comments
    const hasExpandedDiscussionOnLeft =
      left?.discussions?.length > 0 ? left?.discussionsExpanded : false;
    const hasExpandedDiscussionOnRight =
      right?.discussions?.length > 0 ? right?.discussionsExpanded : false;

    const renderCommentRow =
      hasExpandedDiscussionOnLeft ||
      hasExpandedDiscussionOnRight ||
      left?.hasForm ||
      right?.hasForm;

    if (left) {
      left = {
        ...left,
        renderDiscussion: hasExpandedDiscussionOnLeft,
        hasDraft: hasParallelDraftLeft(diffFile.file_hash, line),
        lineDrafts: draftsForLine(diffFile.file_hash, line, 'left'),
        hasCommentForm: left.hasForm,
        isConflictMarker:
          line.left.type === CONFLICT_MARKER_OUR || line.left.type === CONFLICT_MARKER_THEIR,
        emptyCellClassMap: { conflict_our: line.right?.type === CONFLICT_THEIR },
        addCommentTooltip: addCommentTooltip(line.left),
      };
    }
    if (right) {
      right = {
        ...right,
        renderDiscussion: Boolean(
          hasExpandedDiscussionOnRight && right.type && right.type !== EXPANDED_LINE_TYPE,
        ),
        hasDraft: hasParallelDraftRight(diffFile.file_hash, line),
        lineDrafts: draftsForLine(diffFile.file_hash, line, 'right'),
        hasCommentForm: Boolean(right.hasForm && right.type && right.type !== EXPANDED_LINE_TYPE),
        emptyCellClassMap: { conflict_their: line.left?.type === CONFLICT_OUR },
        addCommentTooltip: addCommentTooltip(line.right),
      };
    }

    return {
      ...line,
      left,
      right,
      isMatchLineLeft: isMatchLine(left?.type),
      isMatchLineRight: isMatchLine(right?.type),
      isContextLineLeft: isContextLine(left?.type),
      isContextLineRight: isContextLine(right?.type),
      hasDiscussionsLeft: hasDiscussions(left),
      hasDiscussionsRight: hasDiscussions(right),
      lineHrefOld: lineHref(left, diffFile),
      lineHrefNew: lineHref(right, diffFile),
      lineCode: lineCode(line),
      isMetaLineLeft: isMetaLine(left?.type),
      isMetaLineRight: isMetaLine(right?.type),
      draftRowClasses: left?.hasDraft || right?.hasDraft ? '' : 'js-temp-notes-holder',
      renderCommentRow,
      commentRowClasses:
        hasDiscussions(left) || hasDiscussions(right) ? '' : 'js-temp-notes-holder',
    };
  };
