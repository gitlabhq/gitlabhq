const STYLES_MAP = {
  bold: 1,
  italic: 2,
  underline: 4,
  conceal: 8,
  cross: 16,
};

const get256Color = (stack) => {
  if (stack.length < 2 || stack[0] !== '5') {
    return null;
  }

  stack.shift();

  const color = parseInt(stack.shift(), 10);
  if (color < 0 || color > 255) {
    return null;
  }
  return color;
};

/**
 * Reads an ansi "Select Graphic Rendition (SGR)" sequence and returns
 * CSS classes corresponding to it.
 *
 */
export class AnsiEvaluator {
  constructor() {
    this.reset();
  }

  /**
   * Starts evaluation of a "Select Graphic Rendition (SGR)" sequence
   *
   * Sequences ending in 'm' are SGR and set display attributes in the logs
   */
  evaluate(op) {
    if (op?.endsWith('m')) {
      this.#evaluateStack(op.substring(0, op.length - 1).split(';'));
    }
  }

  /**
   * Return currently present classes, should be used once the sequence has been
   * evaluated.
   */
  getClasses() {
    const classes = [];

    if (typeof this.fgColor === 'number') {
      classes.push(`xterm-fg-${this.fgColor}`);
    } else if (typeof this.fgColor === 'string') {
      classes.push(`term-fg-${this.fgColor}`);
    }

    if (this.bgColor !== null) {
      classes.push(`xterm-bg-${this.bgColor}`);
    }

    for (const s in STYLES_MAP) {
      // eslint-disable-next-line no-bitwise
      if ((this.styleMask & STYLES_MAP[s]) !== 0) {
        classes.push(`term-${s}`);
      }
    }

    return classes;
  }

  /**
   * Reset the current state to neutral/unassigned styles
   */
  reset() {
    this.fgColor = null;
    this.bgColor = null;
    this.styleMask = 0;
  }

  // Private properties

  #evaluateStack(stack) {
    const command = stack.shift();
    if (!command) {
      return;
    }

    switch (command) {
      case '38': {
        const color = get256Color(stack);
        if (color !== null) {
          this.fgColor = color;
        }
        break;
      }
      case '48': {
        const color = get256Color(stack);
        if (color !== null) {
          this.bgColor = color;
        }
        break;
      }
      default: {
        this.#dispatch[command]?.();
      }
    }

    this.#evaluateStack(stack);
  }

  #dispatch = {
    0: () => this.reset(),

    1: () => this.#enableStyle('bold'),
    3: () => this.#enableStyle('italic'),
    4: () => this.#enableStyle('underline'),
    8: () => this.#enableStyle('conceal'),
    9: () => this.#enableStyle('cross'),

    21: () => this.#disableStyle('bold'),
    22: () => this.#disableStyle('bold'),
    23: () => this.#disableStyle('italic'),
    24: () => this.#disableStyle('underline'),
    28: () => this.#disableStyle('conceal'),
    29: () => this.#disableStyle('cross'),

    // Most terminals show bold colored text in the bright color variant
    // only 3 and 4-bit foreground colors are modified.
    30: () => this.#setFg('black'),
    31: () => this.#setFg('red'),
    32: () => this.#setFg('green'),
    33: () => this.#setFg('yellow'),
    34: () => this.#setFg('blue'),
    35: () => this.#setFg('magenta'),
    36: () => this.#setFg('cyan'),
    37: () => this.#setFg('white'),
    39: () => this.#setFg(null),

    40: () => this.#setBg(0),
    41: () => this.#setBg(1),
    42: () => this.#setBg(2),
    43: () => this.#setBg(3),
    44: () => this.#setBg(4),
    45: () => this.#setBg(5),
    46: () => this.#setBg(6),
    47: () => this.#setBg(7),
    49: () => this.#setBg(null),

    90: () => this.#setFg(8),
    91: () => this.#setFg(9),
    92: () => this.#setFg(10),
    93: () => this.#setFg(11),
    94: () => this.#setFg(12),
    95: () => this.#setFg(13),
    96: () => this.#setFg(14),
    97: () => this.#setFg(15),
    99: () => this.#setFg(null),

    100: () => this.#setBg(8),
    101: () => this.#setBg(9),
    102: () => this.#setBg(10),
    103: () => this.#setBg(11),
    104: () => this.#setBg(12),
    105: () => this.#setBg(13),
    106: () => this.#setBg(14),
    107: () => this.#setBg(15),
    109: () => this.#setBg(null),
  };

  #enableStyle(flag) {
    // eslint-disable-next-line no-bitwise
    this.styleMask |= STYLES_MAP[flag];
  }

  #disableStyle(flag) {
    // eslint-disable-next-line no-bitwise
    this.styleMask &= ~STYLES_MAP[flag];
  }

  #setFg(color) {
    this.fgColor = color;
  }

  #setBg(color) {
    this.bgColor = color;
  }
}
