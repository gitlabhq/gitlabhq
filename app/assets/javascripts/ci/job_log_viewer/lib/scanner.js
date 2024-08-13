import { AnsiEvaluator } from './ansi_evaluator';

const SECTION_PREFIX = 'section_';
const SECTION_START = 'start';
const SECTION_END = 'end';
const SECTION_SEPARATOR = ':';

const ANSI_CSI = '\u001b[';
const CR_LINE_ENDING = '\r';

/**
 * Runner timestamped log lines have a header in the format of:
 *
 * - RFC3339Nano UTC timestamp (27 chars)
 * - A space (1 char)
 * - 2-digit hex encoded stream ID (2 chars)
 * - A flag (O and E) representing stdout and stderr (1 char)
 * - Append flag '+' (plus) if the line was a continuation of the last and ' ' (blank space) if not (1 char)
 *
 * Example:
 *
 * 2024-06-12T10:27:13.765080Z 00O Line content
 */
const RUNNER_LOG_LINE_HEADER_REGEX =
  /(\d{4}-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.[0-9]{6}Z) [0-9a-f]{2}[EO][+ ]/;
const RFC3339_DATETIME_LENGTH = 27;
const RUNNER_LOG_LINE_METADATA_LENGTH = 5;
const RUNNER_LOG_LINE_HEADER_LENGTH = RFC3339_DATETIME_LENGTH + RUNNER_LOG_LINE_METADATA_LENGTH;

/**
 * Parses section delimiters in the shape:
 *
 * section_start:1234567890:my_section_name[options]
 * section_end:1234567890:my_section_name
 *
 * @param {string} input
 * @param {number} offset
 * @returns Each part of the section delimiter in an array as well as a new char offset
 */
const parseSection = (input, offset) => {
  const from = offset;
  let to = offset;

  for (; to < input.length; to += 1) {
    const c = input[to];

    // if we find CR, indicates ending of section line
    if (c === CR_LINE_ENDING) {
      to += 1;
      break;
    }
  }

  const section = input
    .slice(from, to)
    .split(SECTION_SEPARATOR)
    .map((s) => s.trim());

  // Validate section is correctly formed
  if (
    section.length === 3 &&
    (section[0] === SECTION_START || section[0] === SECTION_END) &&
    !Number.isNaN(Number(section[1])) &&
    section[2]
  ) {
    return [section, to];
  }

  return [null, to];
};

const parseSectionOptions = (optionsStr = '') => {
  return optionsStr.split(',').reduce((acc, option) => {
    const [key, value] = option.split('=');
    return {
      ...acc,
      [key]: value,
    };
  }, {});
};

const parseAnsi = (input, offset) => {
  const from = offset;
  let to = offset;

  // find any number of parameter bytes (0x30-0x3f)
  for (; to < input.length; to += 1) {
    const c = input.charCodeAt(to);
    if (!(c >= 0x30 && c <= 0x3f)) {
      break;
    }
  }

  // any number of intermediate bytes (0x20–0x2f)
  for (; to < input.length; to += 1) {
    const c = input.charCodeAt(to);
    if (!(c >= 0x20 && c <= 0x2f)) {
      break;
    }
  }

  // single final byte (0x40–0x7e)
  const c = input.charCodeAt(to);
  if (c >= 0x40 && c <= 0x7e) {
    to += 1;
  }

  return [input.slice(from, to), to];
};

export default class {
  constructor() {
    this.ansi = new AnsiEvaluator();
    this.content = [];
    this.sections = [];
    this.timestamped = null;
  }

  scan(rawLine) {
    let input = rawLine;
    let append = false;
    let timestamp;

    // Only checks for timestamped logs once
    // Runners are guaranteed to provide timestamp on each line or none at all
    if (this.timestamped === null) {
      this.timestamped = Boolean(rawLine.match(RUNNER_LOG_LINE_HEADER_REGEX));
    }

    if (this.timestamped) {
      timestamp = rawLine.slice(0, RFC3339_DATETIME_LENGTH);
      append = rawLine[RUNNER_LOG_LINE_HEADER_LENGTH - 1] === '+';
      input = rawLine.slice(RUNNER_LOG_LINE_HEADER_LENGTH);
    }

    this.addLine(input);

    const { content } = this;
    this.content = [];

    const section = this.sections[this.sections.length - 1];

    if (section?.start) {
      section.start = false;
      return {
        timestamp,
        header: section.name,
        options: section.options,
        content,
        sections: this.sections.map(({ name }) => name).slice(0, -1),
      };
    }

    if (content.length) {
      if (append) {
        return {
          timestamp, // timestamp is updated by most recent content
          content,
          append: true,
        };
      }

      return {
        timestamp,
        content,
        sections: this.sections.map(({ name }) => name),
      };
    }

    return null;
  }

  addLine(input) {
    let start = 0;
    let offset = 0;

    while (offset < input.length) {
      if (input.startsWith(ANSI_CSI, offset)) {
        this.addLineContent(input.slice(start, offset));

        let op;
        [op, offset] = parseAnsi(input, offset + ANSI_CSI.length);

        this.ansi.evaluate(op);

        start = offset;
      } else if (input.startsWith(SECTION_PREFIX, offset)) {
        this.addLineContent(input.slice(start, offset));

        let section;
        [section, offset] = parseSection(input, offset + SECTION_PREFIX.length);

        if (section !== null) {
          this.handleSection(section[0], section[1], section[2]);
          start = offset;
        }
      } else {
        offset += 1;
      }
    }

    this.addLineContent(input.slice(start, offset));
  }

  addLineContent(line) {
    const parts = line.split(CR_LINE_ENDING).filter(Boolean);
    const text = parts[parts.length - 1];

    if (!text) {
      return;
    }

    this.content.push({
      style: this.ansi.getClasses(),
      text,
    });
  }

  handleSection(type, time, name) {
    switch (type) {
      case SECTION_START: {
        const section = { name, time, start: true };

        // Find options of a section with shape: section_name[key=value]
        const optsFrom = name.indexOf('[');
        const optsTo = name.lastIndexOf(']');
        if (optsFrom > 0 && optsTo > optsFrom) {
          section.name = name.substring(0, optsFrom);
          section.options = parseSectionOptions(name.substring(optsFrom + 1, optsTo));
        }

        this.sections.push(section);
        break;
      }
      case SECTION_END: {
        if (this.sections.length === 0) {
          return;
        }

        const section = this.sections[this.sections.length - 1];
        if (section.name === name) {
          this.sections.pop();
        }
        break;
      }
      default:
    }
  }
}
