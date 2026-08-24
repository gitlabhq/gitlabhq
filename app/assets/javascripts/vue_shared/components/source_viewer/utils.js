const BLAME_INFO_CLASSLIST = ['gl-border-t', 'gl-border-gray-500', '-gl-mt-px'];
const VIEWER_SELECTOR = '.file-holder .blob-viewer';

const findLineNumberElement = (lineNumber) => document.getElementById(`L${lineNumber}`);

const findLineContentElement = (lineNumber) => document.getElementById(`LC${lineNumber}`);

export const calculateBlameOffset = (lineNumber) => {
  if (lineNumber === 1) return '0px';
  const lineContentEl = findLineContentElement(lineNumber);
  if (!lineContentEl) return null;
  const blobViewerOffset = document.querySelector(VIEWER_SELECTOR)?.getBoundingClientRect().top;
  return `${lineContentEl.getBoundingClientRect().top - blobViewerOffset}px`;
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

/**
 * Blame groups are requested per chunk and appended in fetch-completion order,
 * so the flat list can be out of order, and a commit whose block straddles two
 * requests arrives as two consecutive groups for the same SHA.
 *
 * Sorting and merging those back together yields one group per contiguous run of
 * lines, so every group maps to a single grid cell with no gaps between them.
 *
 * Merging on overlap, not just exact contiguity, keeps that true when the same
 * group is delivered twice: a duplicate is absorbed rather than pushed through
 * as a second group stacked on the first under the same key.
 */
export const normalizeBlameGroups = (blameData) =>
  [...blameData]
    .sort((a, b) => a.lineno - b.lineno)
    .reduce((groups, group) => {
      const previous = groups[groups.length - 1];
      const span = group.span || 1;
      const extendsPrevious =
        previous &&
        previous.commit?.sha === group.commit?.sha &&
        group.lineno <= previous.lineno + previous.span;

      if (extendsPrevious) {
        previous.span = Math.max(previous.span, group.lineno + span - previous.lineno);
      } else {
        groups.push({ ...group, span });
      }

      return groups;
    }, []);

/**
 * Maps blame groups onto the grid rows of a single chunk.
 *
 * Groups that start before the chunk or run past its last line are clamped to
 * the lines the chunk actually renders, so a group can never span a gap into
 * lines that are not on screen. Returns 1-based grid row positions.
 */
export const blameGroupsForChunk = (blameGroups, chunk) => {
  const chunkStart = chunk.startingFrom + 1;
  const chunkEnd = chunk.startingFrom + chunk.totalLines;

  return blameGroups.reduce((result, group) => {
    const span = group.span || 1;
    const groupEnd = group.lineno + span - 1;
    const overlapsChunk = groupEnd >= chunkStart && group.lineno <= chunkEnd;
    if (!overlapsChunk) return result;

    const firstLine = Math.max(group.lineno, chunkStart);
    const lastLine = Math.min(groupEnd, chunkEnd);

    result.push({
      ...group,
      rowStart: firstLine - chunk.startingFrom,
      rowSpan: lastLine - firstLine + 1,
      // Two groups take no separator border: one clamped at the chunk's top
      // edge, which continues a block from the previous chunk rather than
      // opening one, and the block on line 1, which has nothing above it.
      hasSeparator: group.lineno >= chunkStart && group.lineno > 1,
    });

    return result;
  }, []);
};
