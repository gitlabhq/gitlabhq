import { getFormData } from '~/diffs/store/utils';

export const getDraftReplyFormData = (data) => ({
  endpoint: data.notesData.draftsPath,
  data,
});

export const getDraftFormData = (params) => ({
  endpoint: params.notesData.draftsPath,
  data: getFormData(params),
});

export const parallelLineKey = (line, side) => (line[side] ? line[side].line_code : '');

export const showDraftOnSide = (line, side) => {
  // inline mode
  if (side === null) {
    return true;
  }

  // parallel
  if (side === 'left' || side === 'right') {
    const otherSide = side === 'left' ? 'right' : 'left';
    const thisCode = (line[side] && line[side].line_code) || '';
    const otherCode = (line[otherSide] && line[otherSide].line_code) || '';

    // either the lineCodes are different
    // or if they're the same, only show on the left side
    if (thisCode !== otherCode || (side === 'left' && thisCode === otherCode)) {
      return true;
    }
  }

  return false;
};
