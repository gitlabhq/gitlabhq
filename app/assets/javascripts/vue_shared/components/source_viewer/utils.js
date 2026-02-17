const BLAME_INFO_CLASSLIST = ['gl-border-t', 'gl-border-gray-500', '-gl-mt-px'];
const VIEWER_SELECTOR = '.file-holder .blob-viewer';

const findLineNumberElement = (lineNumber) => document.getElementById(`L${lineNumber}`);

const findLineContentElement = (lineNumber) => document.getElementById(`LC${lineNumber}`);

export const calculateBlameOffset = (lineNumber) => {
  if (lineNumber === 1) return '0px';
  const blobViewerOffset = document.querySelector(VIEWER_SELECTOR)?.getBoundingClientRect().top;
  const lineContentOffset = findLineContentElement(lineNumber)?.getBoundingClientRect().top;
  return `${lineContentOffset - blobViewerOffset}px`;
};

export const shouldRender = (data, index) => {
  const prevBlame = data[index - 1];
  const currBlame = data[index];
  const identicalSha = currBlame.commit.sha === prevBlame?.commit?.sha;
  const lineNumberSmaller = currBlame.lineno < prevBlame?.lineno;

  return !identicalSha || lineNumberSmaller;
};

export const toggleBlameLineBorders = (blameData, isVisible) => {
  /**
   * Adds/removes top border to lines that start a new blame block
   */
  const method = isVisible ? 'add' : 'remove';
  blameData.forEach(({ lineno }, index) => {
    if (!shouldRender(blameData, index)) return;

    const lineNumberEl = findLineNumberElement(lineno)?.parentElement;
    const lineContentEl = findLineContentElement(lineno);

    lineNumberEl?.classList[method](...BLAME_INFO_CLASSLIST);
    lineContentEl?.classList[method](...BLAME_INFO_CLASSLIST);
  });
};

/**
 * Checks if any blame data exists for a given chunk's line range.
 * Used to determine if a skeleton loader should still be shown for a chunk.
 */
export const hasBlameDataForChunk = (blameData, chunk) => {
  const startLine = chunk.startingFrom + 1;
  const endLine = chunk.startingFrom + chunk.totalLines;
  return blameData.some((b) => b.lineno >= startLine && b.lineno <= endLine);
};
