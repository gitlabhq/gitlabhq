import axios from '~/lib/utils/axios_utils';

const UNFOLD_COUNT = 20;

// eslint-disable-next-line max-params
const getRequestParams = (expandPrevLine, oldLineNumber, newLineNumber, prevNewLineNumber) => {
  const offset = newLineNumber - oldLineNumber;
  let since;
  let to;
  let unfold = true;

  if (!expandPrevLine) {
    const lineNumber = newLineNumber + 1;
    since = lineNumber;
    to = lineNumber + UNFOLD_COUNT;
  } else {
    const lineNumber = newLineNumber - 1;
    since = lineNumber - UNFOLD_COUNT;
    to = lineNumber;

    // make sure we aren't loading more than we need
    if (since <= prevNewLineNumber + 1) {
      since = prevNewLineNumber + 1;
      unfold = false;
    }
  }

  return { since, to, bottom: !expandPrevLine, offset, unfold };
};

export const getLines = async ({ expandPrevLine, lineData, blobDiffPath, view }) => {
  const params = getRequestParams(expandPrevLine, ...lineData);
  const { data: lines } = await axios.get(blobDiffPath, { params: { ...params, view } });
  return lines;
};
