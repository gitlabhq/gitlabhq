import { parseBoolean } from '../../lib/utils/common_utils';

/**
 * Adds the line number property
 * @param Object line
 * @param Number lineNumber
 */
export const parseLine = (line = {}, lineNumber) => ({
  ...line,
  lineNumber,
});

/**
 * When a line has `section_header` set to true, we create a new
 * structure to allow to nest the lines that belong to the
 * collapsible section
 *
 * @param Object line
 * @param Number lineNumber
 */
export const parseHeaderLine = (line = {}, lineNumber) => ({
  isClosed: parseBoolean(line.section_options?.collapsed),
  isHeader: true,
  line: parseLine(line, lineNumber),
  lines: [],
});

/**
 * Finds the matching header section
 * for the section_duration object and adds it to it
 *
 * {
 *   isHeader: true,
 *   line: {
 *     content: [],
 *     lineNumber: 0,
 *     section_duration: "",
 *   },
 *   lines: []
 * }
 *
 * @param Array data
 * @param Object durationLine
 */
export function addDurationToHeader(data, durationLine) {
  data.forEach((el) => {
    if (el.line && el.line.section === durationLine.section) {
      el.line.section_duration = durationLine.section_duration;
    }
  });
}

/**
 * Check is the current section belongs to a collapsible section
 *
 * @param Array acc
 * @param Object last
 * @param Object section
 *
 * @returns Boolean
 */
export const isCollapsibleSection = (acc = [], last = {}, section = {}) =>
  acc.length > 0 &&
  last.isHeader === true &&
  !section.section_duration &&
  section.section === last.line.section;

/**
 * Returns the lineNumber of the last line in
 * a parsed log
 *
 * @param Array acc
 * @returns Number
 */
export const getIncrementalLineNumber = (acc) => {
  let lineNumberValue;
  const lastIndex = acc.length - 1;
  const lastElement = acc[lastIndex];
  const nestedLines = lastElement.lines;

  if (lastElement.isHeader && !nestedLines.length && lastElement.line) {
    lineNumberValue = lastElement.line.lineNumber;
  } else if (lastElement.isHeader && nestedLines.length) {
    lineNumberValue = nestedLines[nestedLines.length - 1].lineNumber;
  } else {
    lineNumberValue = lastElement.lineNumber;
  }

  return lineNumberValue === 0 ? 1 : lineNumberValue + 1;
};

/**
 * Parses the job log content into a structure usable by the template
 *
 * For collaspible lines (section_header = true):
 *    - creates a new array to hold the lines that are collapsible,
 *    - adds a isClosed property to handle toggle
 *    - adds a isHeader property to handle template logic
 *    - adds the section_duration
 * For each line:
 *    - adds the index as lineNumber
 *
 * @param Array lines
 * @param Array accumulator
 * @returns Array parsed log lines
 */
export const logLinesParserLegacy = (lines = [], accumulator = []) =>
  lines.reduce(
    (acc, line, index) => {
      const lineNumber = accumulator.length > 0 ? getIncrementalLineNumber(acc) : index;

      const last = acc[acc.length - 1];

      // If the object is an header, we parse it into another structure
      if (line.section_header) {
        acc.push(parseHeaderLine(line, lineNumber));
      } else if (isCollapsibleSection(acc, last, line)) {
        // if the object belongs to a nested section, we append it to the new `lines` array of the
        // previously formatted header
        last.lines.push(parseLine(line, lineNumber));
      } else if (line.section_duration) {
        // if the line has section_duration, we look for the correct header to add it
        addDurationToHeader(acc, line);
      } else {
        // otherwise it's a regular line
        acc.push(parseLine(line, lineNumber));
      }

      return acc;
    },
    [...accumulator],
  );

export const logLinesParser = (lines = [], previousTraceState = {}, prevParsedLines = []) => {
  let currentLineCount = previousTraceState?.prevLineCount ?? 0;
  let currentHeader = previousTraceState?.currentHeader;
  let isPreviousLineHeader = previousTraceState?.isPreviousLineHeader ?? false;
  const parsedLines = prevParsedLines.length > 0 ? prevParsedLines : [];
  const sectionsQueue = previousTraceState?.sectionsQueue ?? [];

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    // First run we can use the current index, later runs we have to retrieve the last number of lines
    currentLineCount = previousTraceState?.prevLineCount ? currentLineCount + 1 : i + 1;

    if (line.section_header && !isPreviousLineHeader) {
      // If there's no previous line header that means we're at the root of the log

      isPreviousLineHeader = true;
      parsedLines.push(parseHeaderLine(line, currentLineCount));
      currentHeader = { index: parsedLines.length - 1 };
    } else if (line.section_header && isPreviousLineHeader) {
      // If there's a current section, we can't push to the parsedLines array
      sectionsQueue.push(currentHeader);
      currentHeader = parseHeaderLine(line, currentLineCount); // Let's parse the incoming header line
    } else if (line.section && !line.section_duration) {
      // We're inside a collapsible section and want to parse a standard line
      if (currentHeader?.index) {
        // If the current section header is only an index, add the line as part of the lines
        // array of the current collapsible section
        parsedLines[currentHeader.index].lines.push(parseLine(line, currentLineCount));
      } else {
        // Otherwise add it to the innermost collapsible section lines array
        currentHeader.lines.push(parseLine(line, currentLineCount));
      }
    } else if (line.section && line.section_duration) {
      // NOTE: This marks the end of a section_header
      const previousSection = sectionsQueue.pop();

      // Add the duration to section header
      // If at the root, just push the end to the current parsedLine,
      // otherwise, push it to the previous sections queue
      if (currentHeader?.index) {
        parsedLines[currentHeader.index].line.section_duration = line.section_duration;
        isPreviousLineHeader = false;
        currentHeader = null;
      } else {
        currentHeader.line.section_duration = line.section_duration;

        if (previousSection && previousSection?.index) {
          // Is the previous section on root?
          parsedLines[previousSection.index].lines.push(currentHeader);
        } else if (previousSection && !previousSection?.index) {
          previousSection.lines.push(currentHeader);
        }

        currentHeader = previousSection;
      }
    } else {
      parsedLines.push(parseLine(line, currentLineCount));
    }
  }

  return {
    parsedLines,
    auxiliaryPartialTraceHelpers: {
      isPreviousLineHeader,
      currentHeader,
      sectionsQueue,
      prevLineCount: currentLineCount,
    },
  };
};

/**
 * Finds the repeated offset, removes the old one
 *
 * Returns a new array with the updated log without
 * the repeated offset
 *
 * @param Array newLog
 * @param Array oldParsed
 * @returns Array
 *
 */
export const findOffsetAndRemove = (newLog = [], oldParsed = []) => {
  const cloneOldLog = [...oldParsed];
  const lastIndex = cloneOldLog.length - 1;
  const last = cloneOldLog[lastIndex];

  const firstNew = newLog[0];

  if (last && firstNew) {
    if (last.offset === firstNew.offset || (last.line && last.line.offset === firstNew.offset)) {
      cloneOldLog.splice(lastIndex);
    } else if (last.lines && last.lines.length) {
      const lastNestedIndex = last.lines.length - 1;
      const lastNested = last.lines[lastNestedIndex];
      if (lastNested.offset === firstNew.offset) {
        last.lines.splice(lastNestedIndex);
      }
    }
  }

  return cloneOldLog;
};

/**
 * When the trace is not complete, backend may send the last received line
 * in the new response.
 *
 * We need to check if that is the case by looking for the offset property
 * before parsing the incremental part
 *
 * @param array oldLog
 * @param array newLog
 */
export const updateIncrementalTrace = (newLog = [], oldParsed = []) => {
  const parsedLog = findOffsetAndRemove(newLog, oldParsed);

  return logLinesParserLegacy(newLog, parsedLog);
};
