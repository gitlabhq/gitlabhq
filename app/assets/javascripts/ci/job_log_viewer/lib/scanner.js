import { AnsiEvaluator } from './ansi_evaluator';

const SECTION_PREFIX = 'section_';
const SECTION_START = 'start';
const SECTION_END = 'end';
const SECTION_SEPARATOR = ':';

const ANSI_CSI = '\u001b[';
const CR_LINE_ENDING = '\r';

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
  if (section.length === 3) {
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
  }

  scan(input) {
    let start = 0;
    let offset = 0;

    while (offset < input.length) {
      if (input.startsWith(ANSI_CSI, offset)) {
        this.append(input.slice(start, offset));

        let op;
        [op, offset] = parseAnsi(input, offset + ANSI_CSI.length);

        this.ansi.evaluate(op);

        start = offset;
      } else if (input.startsWith(SECTION_PREFIX, offset)) {
        this.append(input.slice(start, offset));

        let section;
        [section, offset] = parseSection(input, offset + SECTION_PREFIX.length);

        if (section !== null) {
          this.handleSection(section[0], section[1], section[2]);
        }

        start = offset;
      } else {
        offset += 1;
      }
    }

    this.append(input.slice(start, offset));

    const { content } = this;
    this.content = [];

    const section = this.sections[this.sections.length - 1];

    if (section?.start) {
      section.start = false;
      // returns a header line, which can toggle other lines
      return {
        header: section.name,
        options: section.options,
        sections: this.sections.map(({ name }) => name).slice(0, -1),
        content,
      };
    }

    return {
      sections: this.sections.map(({ name }) => name),
      content,
    };
  }

  append(text) {
    if (text.length === 0) {
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
          const duration = time - section.time;
          this.content.push({ section: name, duration });
          this.sections.pop();
        }
        break;
      }
      default:
    }
  }
}
