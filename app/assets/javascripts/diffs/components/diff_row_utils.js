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

export const lineHref = (line) => `#${line?.line_code || ''}`;

export const lineCode = (line) => {
  if (!line) return undefined;
  return line.line_code || line.left?.line_code || line.right?.line_code;
};

export const classNameMapCell = ({ line, hll, isLoggedIn, isHover }) => {
  if (!line) return [];
  const { type } = line;

  return [
    type,
    {
      hll,
      [LINE_HOVER_CLASS_NAME]: isLoggedIn && isHover && !isContextLine(type) && !isMetaLine(type),
      old_line: line.type === 'old',
      new_line: line.type === 'new',
    },
  ];
};

export const addCommentTooltip = (line) => {
  let tooltip;
  if (!line) return tooltip;

  tooltip = __('Add a comment to this line or drag for multiple lines');
  const brokenSymlinks = line.commentsDisabled;

  if (brokenSymlinks) {
    if (brokenSymlinks.wasSymbolic || brokenSymlinks.isSymbolic) {
      tooltip = __(
        'Commenting on symbolic links that replace or are replaced by files is currently not supported.',
      );
    } else if (brokenSymlinks.wasReal || brokenSymlinks.isReal) {
      tooltip = __(
        'Commenting on files that replace or are replaced by symbolic links is currently not supported.',
      );
    }
  }

  return tooltip;
};

export const parallelViewLeftLineType = (line, hll) => {
  if (line?.right?.type === NEW_NO_NEW_LINE_TYPE) {
    return OLD_NO_NEW_LINE_TYPE;
  }

  const lineTypeClass = line?.left ? line.left.type : EMPTY_CELL_TYPE;

  return [lineTypeClass, { hll }];
};

export const shouldShowCommentButton = (hover, context, meta, discussions) => {
  return hover && !context && !meta && !discussions;
};

export const mapParallel = (content) => (line) => {
  let { left, right } = line;

  // Dicussions/Comments
  const hasExpandedDiscussionOnLeft =
    left?.discussions?.length > 0 ? left?.discussionsExpanded : false;
  const hasExpandedDiscussionOnRight =
    right?.discussions?.length > 0 ? right?.discussionsExpanded : false;

  const renderCommentRow =
    hasExpandedDiscussionOnLeft || hasExpandedDiscussionOnRight || left?.hasForm || right?.hasForm;

  if (left) {
    left = {
      ...left,
      renderDiscussion: hasExpandedDiscussionOnLeft,
      hasDraft: content.hasParallelDraftLeft(content.diffFile.file_hash, line),
      lineDraft: content.draftForLine(content.diffFile.file_hash, line, 'left'),
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
      renderDiscussion: Boolean(hasExpandedDiscussionOnRight && right.type),
      hasDraft: content.hasParallelDraftRight(content.diffFile.file_hash, line),
      lineDraft: content.draftForLine(content.diffFile.file_hash, line, 'right'),
      hasCommentForm: Boolean(right.hasForm && right.type),
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
    lineHrefOld: lineHref(left),
    lineHrefNew: lineHref(right),
    lineCode: lineCode(line),
    isMetaLineLeft: isMetaLine(left?.type),
    isMetaLineRight: isMetaLine(right?.type),
    draftRowClasses: left?.lineDraft > 0 || right?.lineDraft > 0 ? '' : 'js-temp-notes-holder',
    renderCommentRow,
    commentRowClasses: hasDiscussions(left) || hasDiscussions(right) ? '' : 'js-temp-notes-holder',
  };
};
