import { parseBoolean } from '~/lib/utils/common_utils';

/**
 * Filters out lines that have an offset lower than the offset provided.
 *
 * If no offset is provided, all the lines are returned back.
 *
 * @param {Array} newLines
 * @param {Number} offset
 * @returns Lines to be added to the log that have not been added.
 */
const linesAfterOffset = (newLines = [], offset = -1) => {
  if (offset === -1) {
    return newLines;
  }
  return newLines.filter((newLine) => newLine.offset > offset);
};

/**
 * Parses a series of trace lines from a job and returns lines and
 * sections of the log. Each line is annotated with a lineNumber.
 *
 * Sections have a range: starting line and ending line, plus a
 * "duration" string.
 *
 * @param {Array} newLines - Lines to add to the log
 * @param {Object} currentState - Current log: lines and sections
 * @returns Consolidated lines and sections to be displayed
 */
export const logLinesParser = (
  newLines = [],
  { currentLines = [], currentSections = {} } = {},
  hash = '',
) => {
  const lastCurrentLine = currentLines[currentLines.length - 1];
  const newLinesToAppend = linesAfterOffset(newLines, lastCurrentLine?.offset);

  if (!newLinesToAppend.length) {
    return { lines: currentLines, sections: currentSections };
  }

  let lineNumber = lastCurrentLine?.lineNumber || 0;
  const lines = [...currentLines];
  const sections = { ...currentSections };

  newLinesToAppend.forEach((line) => {
    const {
      offset,
      content,
      section,
      section_header: isHeader,
      section_footer: isFooter,
      section_duration: duration,
      section_options: options,
    } = line;

    if (content.length) {
      lineNumber += 1;
      lines.push({
        offset,
        lineNumber,
        content,
        ...(section ? { section } : {}),
        ...(isHeader ? { isHeader: true } : {}),
      });
    }

    // root level lines have no section, skip creating one
    if (section) {
      sections[section] = sections[section] || {
        startLineNumber: 0,
        endLineNumber: Infinity, // by default, sections are unbounded / have no end
        duration: null,
        isClosed: false,
      };

      if (isHeader) {
        sections[section].startLineNumber = lineNumber;
      }
      if (options) {
        let isClosed = parseBoolean(options?.collapsed);
        // if a hash is present in the URL then we ensure
        // all sections are visible so we can scroll to the hash
        // in the DOM
        if (hash) {
          isClosed = false;
        }
        sections[section].isClosed = isClosed;

        const hideDuration = parseBoolean(options?.hide_duration);
        if (hideDuration) {
          sections[section].hideDuration = hideDuration;
        }
      }
      if (duration) {
        sections[section].duration = duration;
      }
      if (isFooter) {
        sections[section].endLineNumber = lineNumber;
      }
    }
  });

  return { lines, sections };
};
