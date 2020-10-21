import { __ } from '~/locale';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
} from '../constants';

export const isHighlighted = (state, line, isCommented) => {
  if (isCommented) return true;

  const lineCode = line?.line_code;
  return lineCode ? lineCode === state.diffs.highlightedRow : false;
};

export const isContextLine = type => type === CONTEXT_LINE_TYPE;

export const isMatchLine = type => type === MATCH_LINE_TYPE;

export const isMetaLine = type =>
  [OLD_NO_NEW_LINE_TYPE, NEW_NO_NEW_LINE_TYPE, EMPTY_CELL_TYPE].includes(type);

export const shouldRenderCommentButton = (isLoggedIn, isCommentButtonRendered) => {
  return isCommentButtonRendered && isLoggedIn;
};

export const hasDiscussions = line => line?.discussions?.length > 0;

export const lineHref = line => `#${line?.line_code || ''}`;

export const lineCode = line => {
  if (!line) return undefined;
  return line.line_code || line.left?.line_code || line.right?.line_code;
};

export const classNameMapCell = (line, hll, isLoggedIn, isHover) => {
  if (!line) return [];
  const { type } = line;

  return [
    type,
    {
      hll,
      [LINE_HOVER_CLASS_NAME]: isLoggedIn && isHover && !isContextLine(type) && !isMetaLine(type),
    },
  ];
};

export const addCommentTooltip = line => {
  let tooltip;
  if (!line) return tooltip;

  tooltip = __('Add a comment to this line');
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
