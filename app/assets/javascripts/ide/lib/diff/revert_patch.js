export function revertPatch(source, uniDiff, options = {}) {
  if (typeof uniDiff === 'string') {
    uniDiff = parsePatch(uniDiff);
  }

  if (Array.isArray(uniDiff)) {
    if (uniDiff.length > 1) {
      throw new Error('applyPatch only works with a single input.');
    }

    uniDiff = uniDiff[0];
  }

  // Apply the diff to the input
  let lines = source.split(/\r\n|[\n\v\f\r\x85]/),
    delimiters = source.match(/\r\n|[\n\v\f\r\x85]/g) || [],
    hunks = uniDiff.hunks,
    compareLine =
      options.compareLine ||
      ((lineNumber, line, operation, patchContent) => line === patchContent),
    errorCount = 0,
    fuzzFactor = options.fuzzFactor || 0,
    minLine = 0,
    offset = 0,
    removeEOFNL,
    addEOFNL;

  /**
   * Checks if the hunk exactly fits on the provided location
   */
  function hunkFits(hunk, toPos) {
    for (let j = 0; j < hunk.lines.length; j++) {
      let line = hunk.lines[j],
        operation = line[0],
        content = line.substr(1);

      if (operation === ' ' || operation === '-') {
        // Context sanity check
        if (!compareLine(toPos + 1, lines[toPos], operation, content)) {
          errorCount++;

          if (errorCount > fuzzFactor) {
            return false;
          }
        }
        toPos++;
      }
    }

    return true;
  }

  // Search best fit offsets for each hunk based on the previous ones
  for (let i = 0; i < hunks.length; i++) {
    let hunk = hunks[i],
      maxLine = lines.length - hunk.oldLines,
      localOffset = 0,
      toPos = offset + hunk.oldStart - 1;

    const iterator = distanceIterator(toPos, minLine, maxLine);

    for (; localOffset !== undefined; localOffset = iterator()) {
      if (hunkFits(hunk, toPos + localOffset)) {
        hunk.offset = offset += localOffset;
        break;
      }
    }

    if (localOffset === undefined) {
      return false;
    }

    // Set lower text limit to end of the current hunk, so next ones don't try
    // to fit over already patched text
    minLine = hunk.offset + hunk.oldStart + hunk.oldLines;
  }

  // Apply patch hunks
  let diffOffset = 0;
  for (let i = 0; i < hunks.length; i++) {
    let hunk = hunks[i],
      toPos = hunk.oldStart + hunk.offset + diffOffset - 1;
    diffOffset += hunk.newLines - hunk.oldLines;

    if (toPos < 0) {
      // Creating a new file
      toPos = 0;
    }

    for (let j = 0; j < hunk.lines.length; j++) {
      let line = hunk.lines[j],
        operation = line[0],
        content = line.substr(1),
        delimiter = hunk.linedelimiters[j];

      // Turned around the commands to revert the applying
      if (operation === ' ') {
        toPos++;
      } else if (operation === '+') {
        lines.splice(toPos, 1);
        delimiters.splice(toPos, 1);
        /* istanbul ignore else */
      } else if (operation === '-') {
        lines.splice(toPos, 0, content);
        delimiters.splice(toPos, 0, delimiter);
        toPos++;
      } else if (operation === '\\') {
        const previousOperation = hunk.lines[j - 1]
          ? hunk.lines[j - 1][0]
          : null;
        if (previousOperation === '+') {
          removeEOFNL = true;
        } else if (previousOperation === '-') {
          addEOFNL = true;
        }
      }
    }
  }

  // Handle EOFNL insertion/removal
  if (removeEOFNL) {
    while (!lines[lines.length - 1]) {
      lines.pop();
      delimiters.pop();
    }
  } else if (addEOFNL) {
    lines.push('');
    delimiters.push('\n');
  }
  for (let _k = 0; _k < lines.length - 1; _k++) {
    lines[_k] = lines[_k] + delimiters[_k];
  }
  return lines.join('');
}

/**
 * Utility Function
 * @param {*} start
 * @param {*} minLine
 * @param {*} maxLine
 */
const distanceIterator = function(start, minLine, maxLine) {
  let wantForward = true,
    backwardExhausted = false,
    forwardExhausted = false,
    localOffset = 1;

  return function iterator() {
    if (wantForward && !forwardExhausted) {
      if (backwardExhausted) {
        localOffset++;
      } else {
        wantForward = false;
      }

      // Check if trying to fit beyond text length, and if not, check it fits
      // after offset location (or desired location on first iteration)
      if (start + localOffset <= maxLine) {
        return localOffset;
      }

      forwardExhausted = true;
    }

    if (!backwardExhausted) {
      if (!forwardExhausted) {
        wantForward = true;
      }

      // Check if trying to fit before text beginning, and if not, check it fits
      // before offset location
      if (minLine <= start - localOffset) {
        return -localOffset++;
      }

      backwardExhausted = true;
      return iterator();
    }

    // We tried to fit hunk before text beginning and beyond text length, then
    // hunk can't fit on the text. Return undefined
  };
};
