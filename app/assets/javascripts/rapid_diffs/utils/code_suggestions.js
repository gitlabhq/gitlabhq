import { findApplicablePosition } from '~/rapid_diffs/utils/discussion_position';
import { getNewLinesInRange } from '~/rapid_diffs/utils/line_utils';

export const CODE_SUGGESTIONS_OFF = Object.freeze({
  canSuggest: false,
  lines: [],
  lineType: '',
  showPopover: false,
});

function lineRangeOf(position) {
  if (position.line_range) return position.line_range;
  const line = { old_line: position.old_line, new_line: position.new_line };
  return { start: line, end: line };
}

export function getCodeSuggestionsConfig({
  discussion,
  diffElement,
  diffRefs,
  canReceiveSuggestion,
  blobRawPath,
}) {
  if (!canReceiveSuggestion || !discussion || !diffRefs) return CODE_SUGGESTIONS_OFF;

  const position = findApplicablePosition(discussion, diffRefs);
  if (position?.position_type !== 'text') return CODE_SUGGESTIONS_OFF;

  const range = getNewLinesInRange(diffElement, lineRangeOf(position));
  if (!range) return CODE_SUGGESTIONS_OFF;

  return {
    canSuggest: true,
    lines: range.lines,
    lineType: '',
    showPopover: false,
    blobRawPath,
    lineRange: { start: range.start, end: range.end },
    previewParams: {
      preview_suggestions: true,
      line: range.end,
      file_path: position.new_path,
      base_sha: position.base_sha,
      start_sha: position.start_sha,
      head_sha: position.head_sha,
    },
  };
}
