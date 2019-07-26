const INDENT_SEQUENCE = '    ';

function countLeftSpaces(text) {
  const i = text.split('').findIndex(c => c !== ' ');
  return i === -1 ? text.length : i;
}

/**
 * IndentHelper provides methods that allow manual and smart indentation in
 * textareas. It supports line indent/unindent, selection indent/unindent,
 * auto indentation on newlines, and smart deletion of indents with backspace.
 */
export default class IndentHelper {
  /**
   * Creates a new IndentHelper and binds it to the given `textarea`. You can provide a custom indent sequence in the second parameter, but the `newline` and `backspace` operations may work funny if the indent sequence isn't spaces only.
   */
  constructor(textarea, indentSequence = INDENT_SEQUENCE) {
    this.element = textarea;
    this.seq = indentSequence;
  }

  getSelection() {
    return { start: this.element.selectionStart, end: this.element.selectionEnd };
  }

  isRangeSelection() {
    return this.element.selectionStart !== this.element.selectionEnd;
  }

  /**
   * Re-implementation of textarea's setRangeText method, because IE/Edge don't support it.
   *
   * @see https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#dom-textarea%2Finput-setrangetext
   */
  setRangeText(replacement, start, end, selectMode) {
    // Disable eslint to remain as faithful as possible to the above linked spec
    /* eslint-disable no-param-reassign, no-case-declarations */
    const text = this.element.value;

    if (start > end) {
      throw new RangeError('setRangeText: start index must be less than or equal to end index');
    }

    // Clamp to [0, len]
    start = Math.max(0, Math.min(start, text.length));
    end = Math.max(0, Math.min(end, text.length));

    let selection = { start: this.element.selectionStart, end: this.element.selectionEnd };

    this.element.value = text.slice(0, start) + replacement + text.slice(end);

    const newLength = replacement.length;
    const newEnd = start + newLength;

    switch (selectMode) {
      case 'select':
        selection = { start, newEnd };
        break;
      case 'start':
        selection = { start, end: start };
        break;
      case 'end':
        selection = { start: newEnd, end: newEnd };
        break;
      case 'preserve':
      default:
        const oldLength = end - start;
        const delta = newLength - oldLength;
        if (selection.start > end) {
          selection.start += delta;
        } else if (selection.start > start) {
          selection.start = start;
        }
        if (selection.end > end) {
          selection.end += delta;
        } else if (selection.end > start) {
          selection.end = newEnd;
        }
    }

    this.element.setSelectionRange(selection.start, selection.end);

    /* eslint-enable no-param-reassign, no-case-declarations */
  }

  /**
   * Returns an array of lines in the textarea, with information about their
   * start/end offsets and whether they are included in the current selection.
   */
  splitLines() {
    const { start, end } = this.getSelection();

    const lines = this.element.value.split('\n');
    let textStart = 0;
    const lineObjects = [];
    lines.forEach(line => {
      const lineObj = {
        text: line,
        start: textStart,
        end: textStart + line.length,
      };
      lineObj.inSelection = lineObj.start <= end && lineObj.end >= start;
      lineObjects.push(lineObj);
      textStart += line.length + 1;
    });
    return lineObjects;
  }

  /**
   * Indents selected lines by one level.
   */
  indent() {
    const { start } = this.getSelection();

    const selectedLines = this.splitLines().filter(line => line.inSelection);
    if (!this.isRangeSelection() && start === selectedLines[0].start) {
      // Special case: if cursor is at the beginning of the line, move it one
      // indent right.
      const line = selectedLines[0];
      this.setRangeText(this.seq, line.start, line.start, 'end');
    } else {
      selectedLines.reverse();
      selectedLines.forEach(line => {
        this.setRangeText(INDENT_SEQUENCE, line.start, line.start, 'preserve');
      });
    }
  }

  /**
   * Unindents selected lines by one level.
   */
  unindent() {
    const lines = this.splitLines().filter(line => line.inSelection);
    lines.reverse();
    lines
      .filter(line => line.text.startsWith(this.seq))
      .forEach(line => {
        this.setRangeText('', line.start, line.start + this.seq.length, 'preserve');
      });
  }

  /**
   * Emulates a newline keypress, automatically indenting the new line.
   */
  newline() {
    const { start, end } = this.getSelection();

    if (this.isRangeSelection()) {
      // Manually kill the selection before calculating the indent
      this.setRangeText('', start, end, 'start');
    }

    // Auto-indent the next line
    const currentLine = this.splitLines().find(line => line.end >= start);
    const spaces = countLeftSpaces(currentLine.text);
    this.setRangeText(`\n${' '.repeat(spaces)}`, start, start, 'end');
  }

  /**
   * If the cursor is positioned at the end of a line's leading indents,
   * emulates a backspace keypress by deleting a single level of indents.
   * @param event The DOM KeyboardEvent that triggers this action, or null.
   */
  backspace(event) {
    const { start } = this.getSelection();

    // If the cursor is at the end of leading indents, delete an indent.
    if (!this.isRangeSelection()) {
      const currentLine = this.splitLines().find(line => line.end >= start);
      const cursorPosition = start - currentLine.start;
      if (countLeftSpaces(currentLine.text) === cursorPosition && cursorPosition > 0) {
        if (event) event.preventDefault();

        let spacesToDelete = cursorPosition % this.seq.length;
        if (spacesToDelete === 0) {
          spacesToDelete = this.seq.length;
        }
        this.setRangeText('', start - spacesToDelete, start, 'start');
      }
    }
  }
}
