/* eslint-disable func-names, no-param-reassign, operator-assignment, consistent-return */
import $ from 'jquery';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { insertText } from '~/lib/utils/common_utils';

const LINK_TAG_PATTERN = '[{text}](url)';
const INDENT_CHAR = ' ';
const INDENT_LENGTH = 2;

// at the start of a line, find any amount of whitespace followed by
// a bullet point character (*+-) and an optional checkbox ([ ] [x])
// OR a number with a . after it and an optional checkbox ([ ] [x])
// followed by one or more whitespace characters
const LIST_LINE_HEAD_PATTERN = /^(?<indent>\s*)(?<leader>((?<isUl>[*+-])|(?<isOl>\d+\.))( \[([xX~\s])\])?\s)(?<content>.)?/;

// detect a horizontal rule that might be mistaken for a list item (not full pattern for an <hr>)
const HR_PATTERN = /^((\s{0,3}-+\s*-+\s*-+\s*[\s-]*)|(\s{0,3}\*+\s*\*+\s*\*+\s*[\s*]*))$/;

let compositioningNoteText = false;

function selectedText(text, textarea) {
  return text.substring(textarea.selectionStart, textarea.selectionEnd);
}

function addBlockTags(blockTag, selected) {
  return `${blockTag}\n${selected}\n${blockTag}`;
}

function lineBefore(text, textarea, trimNewlines = true) {
  let split = text.substring(0, textarea.selectionStart);

  if (trimNewlines) {
    split = split.trim();
  }

  split = split.split('\n');

  return split[split.length - 1];
}

function lineAfter(text, textarea, trimNewlines = true) {
  let split = text.substring(textarea.selectionEnd);

  if (trimNewlines) {
    split = split.trim();
  } else {
    // remove possible leading newline to get at the real line
    split = split.replace(/^\n/, '');
  }

  split = split.split('\n');

  return split[0];
}

function convertMonacoSelectionToAceFormat(sel) {
  return {
    start: {
      row: sel.startLineNumber,
      column: sel.startColumn,
    },
    end: {
      row: sel.endLineNumber,
      column: sel.endColumn,
    },
  };
}

function getEditorSelectionRange(editor) {
  return convertMonacoSelectionToAceFormat(editor.getSelection());
}

function editorBlockTagText(text, blockTag, selected, editor) {
  const lines = text.split('\n');
  const selectionRange = getEditorSelectionRange(editor);
  const shouldRemoveBlock =
    lines[selectionRange.start.row - 1] === blockTag &&
    lines[selectionRange.end.row + 1] === blockTag;

  if (shouldRemoveBlock) {
    if (blockTag !== null) {
      const lastLine = lines[selectionRange.end.row + 1];
      const rangeWithBlockTags = new Range(
        lines[selectionRange.start.row - 1],
        0,
        selectionRange.end.row + 1,
        lastLine.length,
      );
      editor.getSelection().setSelectionRange(rangeWithBlockTags);
    }
    return selected;
  }
  return addBlockTags(blockTag, selected);
}

function blockTagText(text, textArea, blockTag, selected) {
  const shouldRemoveBlock =
    lineBefore(text, textArea) === blockTag && lineAfter(text, textArea) === blockTag;

  if (shouldRemoveBlock) {
    // To remove the block tag we have to select the line before & after
    if (blockTag != null) {
      textArea.selectionStart = textArea.selectionStart - (blockTag.length + 1);
      textArea.selectionEnd = textArea.selectionEnd + (blockTag.length + 1);
    }
    return selected;
  }
  return addBlockTags(blockTag, selected);
}

function moveCursor({
  textArea,
  tag,
  cursorOffset,
  positionBetweenTags,
  removedLastNewLine,
  select,
  editor,
  editorSelectionStart,
  editorSelectionEnd,
}) {
  let pos;
  if (textArea && !textArea.setSelectionRange) {
    return;
  }
  if (select && select.length > 0) {
    if (textArea) {
      // calculate the part of the text to be selected
      const startPosition = textArea.selectionStart - (tag.length - tag.indexOf(select));
      const endPosition = startPosition + select.length;
      return textArea.setSelectionRange(startPosition, endPosition);
    } else if (editor) {
      editor.selectWithinSelection(select, tag);
      return;
    }
  }
  if (textArea) {
    if (textArea.selectionStart === textArea.selectionEnd) {
      if (positionBetweenTags) {
        pos = textArea.selectionStart - tag.length;
      } else {
        pos = textArea.selectionStart;
      }

      if (removedLastNewLine) {
        pos -= 1;
      }

      if (cursorOffset) {
        pos -= cursorOffset;
      }

      return textArea.setSelectionRange(pos, pos);
    }
  } else if (editor && editorSelectionStart.row === editorSelectionEnd.row) {
    if (positionBetweenTags) {
      editor.moveCursor(tag.length * -1);
    }
  }
}

export function insertMarkdownText({
  textArea,
  text,
  tag,
  cursorOffset,
  blockTag,
  selected = '',
  wrap,
  select,
  editor,
}) {
  let removedLastNewLine = false;
  let removedFirstNewLine = false;
  let currentLineEmpty = false;
  let editorSelectionStart;
  let editorSelectionEnd;
  let lastNewLine;
  let textToInsert;
  selected = selected.toString();

  if (editor) {
    const selectionRange = getEditorSelectionRange(editor);

    editorSelectionStart = selectionRange.start;
    editorSelectionEnd = selectionRange.end;
  }

  // check for link pattern and selected text is an URL
  // if so fill in the url part instead of the text part of the pattern.
  if (tag === LINK_TAG_PATTERN) {
    if (URL) {
      try {
        new URL(selected); // eslint-disable-line no-new
        // valid url
        tag = '[text]({text})';
        select = 'text';
      } catch (e) {
        // ignore - no valid url
      }
    }
  }

  // Remove the first newline
  if (selected.indexOf('\n') === 0) {
    removedFirstNewLine = true;
    selected = selected.replace(/\n+/, '');
  }

  // Remove the last newline
  if (textArea) {
    if (textArea.selectionEnd - textArea.selectionStart > selected.replace(/\n$/, '').length) {
      removedLastNewLine = true;
      selected = selected.replace(/\n$/, '');
    }
  } else if (editor) {
    if (editorSelectionStart.row !== editorSelectionEnd.row) {
      removedLastNewLine = true;
      selected = selected.replace(/\n$/, '');
    }
  }

  const selectedSplit = selected.split('\n');

  if (editor && !wrap) {
    lastNewLine = editor.getValue().split('\n')[editorSelectionStart.row];

    if (/^\s*$/.test(lastNewLine)) {
      currentLineEmpty = true;
    }
  } else if (textArea && !wrap) {
    lastNewLine = textArea.value.substr(0, textArea.selectionStart).lastIndexOf('\n');

    // Check whether the current line is empty or consists only of spaces(=handle as empty)
    if (/^\s*$/.test(textArea.value.substring(lastNewLine, textArea.selectionStart))) {
      currentLineEmpty = true;
    }
  }

  const isBeginning =
    (textArea && textArea.selectionStart === 0) ||
    (editor && editorSelectionStart.column === 0 && editorSelectionStart.row === 0);

  const startChar = !wrap && !currentLineEmpty && !isBeginning ? '\n' : '';
  const textPlaceholder = '{text}';

  if (selectedSplit.length > 1 && (!wrap || (blockTag != null && blockTag !== ''))) {
    if (blockTag != null && blockTag !== '') {
      textToInsert = editor
        ? editorBlockTagText(text, blockTag, selected, editor)
        : blockTagText(text, textArea, blockTag, selected);
    } else {
      textToInsert = selectedSplit
        .map((val) => {
          if (tag.indexOf(textPlaceholder) > -1) {
            return tag.replace(textPlaceholder, val);
          }
          if (val.indexOf(tag) === 0) {
            return String(val.replace(tag, ''));
          }
          return String(tag) + val;
        })
        .join('\n');
    }
  } else if (tag.indexOf(textPlaceholder) > -1) {
    textToInsert = tag.replace(textPlaceholder, () =>
      selected.replace(/\\n/g, '\n').replace(/%br/g, '\\n'),
    );
  } else {
    textToInsert = String(startChar) + tag + selected + (wrap ? tag : '');
  }

  if (removedFirstNewLine) {
    textToInsert = `\n${textToInsert}`;
  }

  if (removedLastNewLine) {
    textToInsert += '\n';
  }

  if (editor) {
    editor.replaceSelectedText(textToInsert, select);
  } else {
    insertText(textArea, textToInsert);
  }
  return moveCursor({
    textArea,
    tag: tag.replace(textPlaceholder, selected),
    cursorOffset,
    positionBetweenTags: wrap && selected.length === 0,
    removedLastNewLine,
    select,
    editor,
    editorSelectionStart,
    editorSelectionEnd,
  });
}

function updateText({ textArea, tag, cursorOffset, blockTag, wrap, select, tagContent }) {
  const $textArea = $(textArea);
  textArea = $textArea.get(0);
  const text = $textArea.val();
  const selected = selectedText(text, textArea) || tagContent;
  $textArea.focus();
  return insertMarkdownText({
    textArea,
    text,
    tag,
    cursorOffset,
    blockTag,
    selected,
    wrap,
    select,
  });
}

/**
 * Returns the text lines that encompass the current selection
 *
 * @param {Object} textArea - the targeted text area
 * @returns {Object}
 */
function linesFromSelection(textArea) {
  const text = textArea.value;
  const { selectionStart, selectionEnd } = textArea;

  let startPos = text[selectionStart] === '\n' ? selectionStart - 1 : selectionStart;
  startPos = text.lastIndexOf('\n', startPos) + 1;

  let endPos = selectionEnd === selectionStart ? selectionEnd : selectionEnd - 1;
  endPos = text.indexOf('\n', endPos);
  if (endPos < 0) endPos = text.length;

  const selectedRange = text.substring(startPos, endPos);
  const lines = selectedRange.split('\n');

  return {
    lines,
    selectionStart,
    selectionEnd,
    startPos,
    endPos,
  };
}

/**
 * Set the selection of a textarea such that it maintains the
 * previous selection before the lines were indented/outdented
 *
 * @param {Object} textArea - the targeted text area
 * @param {Number} selectionStart - start position of original selection
 * @param {Number} selectionEnd - end position of original selection
 * @param {Number} startPos - start pos of first line
 * @param {Number} firstLineChange - number of characters changed on first line
 * @param {Number} totalChanged - total number of characters changed
 */
function setNewSelectionRange(
  textArea,
  selectionStart,
  selectionEnd,
  startPos,
  firstLineChange,
  totalChanged,
) {
  if (selectionStart === selectionEnd) {
    textArea.setSelectionRange(
      Math.max(0, selectionStart + firstLineChange),
      Math.max(0, selectionEnd + firstLineChange),
    );
  } else if (selectionStart === startPos) {
    textArea.setSelectionRange(selectionStart, Math.max(0, selectionEnd + totalChanged));
  } else {
    textArea.setSelectionRange(
      Math.max(0, selectionStart + firstLineChange),
      Math.max(0, selectionEnd + totalChanged),
    );
  }
}

/**
 * Indents selected lines to the right by 2 spaces
 *
 * @param {Object} textArea - the targeted text area
 */
function indentLines(textArea) {
  const { lines, selectionStart, selectionEnd, startPos, endPos } = linesFromSelection(textArea);
  const shiftedLines = [];
  let totalAdded = 0;

  textArea.setSelectionRange(startPos, endPos);

  lines.forEach((line) => {
    if (line.length > 0) {
      line = INDENT_CHAR.repeat(INDENT_LENGTH) + line;
      totalAdded += INDENT_LENGTH;
    }

    shiftedLines.push(line);
  });

  const textToInsert = shiftedLines.join('\n');

  insertText(textArea, textToInsert);
  setNewSelectionRange(textArea, selectionStart, selectionEnd, startPos, INDENT_LENGTH, totalAdded);
}

/**
 * Outdents selected lines to the left by 2 spaces
 *
 * @param {Object} textArea - the targeted text area
 */
function outdentLines(textArea) {
  const { lines, selectionStart, selectionEnd, startPos, endPos } = linesFromSelection(textArea);
  const shiftedLines = [];
  let totalRemoved = 0;
  let removedFromFirstline = -1;
  let removedFromLine = 0;

  textArea.setSelectionRange(startPos, endPos);

  lines.forEach((line) => {
    removedFromLine = 0;

    if (line.length > 0) {
      // need to count how many spaces are actually removed, so can't use `replace`
      while (removedFromLine < INDENT_LENGTH && line[removedFromLine] === INDENT_CHAR) {
        removedFromLine += 1;
      }

      if (removedFromLine > 0) {
        line = line.slice(removedFromLine);
        totalRemoved += removedFromLine;
      }
    }

    if (removedFromFirstline === -1) removedFromFirstline = removedFromLine;
    shiftedLines.push(line);
  });

  const textToInsert = shiftedLines.join('\n');

  insertText(textArea, textToInsert);
  setNewSelectionRange(
    textArea,
    selectionStart,
    selectionEnd,
    startPos,
    -removedFromFirstline,
    -totalRemoved,
  );
}

function handleIndentOutdent(e, textArea) {
  if (!e.metaKey) return;

  switch (e.key) {
    case ']':
      e.preventDefault();
      indentLines(textArea);
      break;
    case '[':
      e.preventDefault();
      outdentLines(textArea);
      break;
    default:
      break;
  }
}

/* eslint-disable @gitlab/require-i18n-strings */
function handleSurroundSelectedText(e, textArea) {
  if (!gon.markdown_surround_selection) return;
  if (e.metaKey) return;
  if (textArea.selectionStart === textArea.selectionEnd) return;

  const keys = {
    '*': '**{text}**', // wraps with bold character
    _: '_{text}_', // wraps with italic character
    '`': '`{text}`', // wraps with inline character
    "'": "'{text}'", // single quotes
    '"': '"{text}"', // double quotes
    '[': '[{text}]', // brackets
    '{': '{{text}}', // braces
    '(': '({text})', // parentheses
    '<': '<{text}>', // angle brackets
  };
  const tag = keys[e.key];

  if (tag) {
    e.preventDefault();

    updateText({
      tag,
      textArea,
      blockTag: '',
      wrap: true,
      select: '',
      tagContent: '',
    });
  }
}
/* eslint-enable @gitlab/require-i18n-strings */

/**
 * Returns the content for a new line following a list item.
 *
 * @param {Object} result - regex match of the current line
 * @param {Object?} nextLineResult - regex match of the next line
 * @returns string with the new list item
 */
function continueOlText(result, nextLineResult) {
  const { indent, leader } = result.groups;
  const { indent: nextIndent, isOl: nextIsOl } = nextLineResult?.groups ?? {};

  const [numStr, postfix = ''] = leader.split('.');

  const incrementBy = nextIsOl && nextIndent === indent ? 0 : 1;
  const num = parseInt(numStr, 10) + incrementBy;

  return `${indent}${num}.${postfix}`;
}

function handleContinueList(e, textArea) {
  if (!(e.key === 'Enter')) return;
  if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
  if (textArea.selectionStart !== textArea.selectionEnd) return;
  // prevent unintended line breaks were inserted using Japanese IME on MacOS
  if (compositioningNoteText) return;

  const currentLine = lineBefore(textArea.value, textArea, false);
  const result = currentLine.match(LIST_LINE_HEAD_PATTERN);

  if (result) {
    const { leader, indent, content, isOl } = result.groups;
    const prevLineEmpty = !content;

    if (prevLineEmpty) {
      // erase previous empty list item - select the text and allow the
      // natural line feed erase the text
      textArea.selectionStart = textArea.selectionStart - result[0].length;
      return;
    }

    let itemToInsert;

    // Behaviors specific to either `ol` or `ul`
    if (isOl) {
      const nextLine = lineAfter(textArea.value, textArea, false);
      const nextLineResult = nextLine.match(LIST_LINE_HEAD_PATTERN);

      itemToInsert = continueOlText(result, nextLineResult);
    } else {
      if (currentLine.match(HR_PATTERN)) return;

      itemToInsert = `${indent}${leader}`;
    }

    itemToInsert = itemToInsert.replace(/\[[x~]\]/i, '[ ]');

    e.preventDefault();

    updateText({
      tag: itemToInsert,
      textArea,
      blockTag: '',
      wrap: false,
      select: '',
      tagContent: '',
    });
  }
}

export function keypressNoteText(e) {
  const textArea = this;

  if ($(textArea).atwho?.('isSelecting')) return;

  handleIndentOutdent(e, textArea);
  handleContinueList(e, textArea);
  handleSurroundSelectedText(e, textArea);
}

export function compositionStartNoteText() {
  compositioningNoteText = true;
}

export function compositionEndNoteText() {
  compositioningNoteText = false;
}

export function updateTextForToolbarBtn($toolbarBtn) {
  return updateText({
    textArea: $toolbarBtn.closest('.md-area').find('textarea'),
    tag: $toolbarBtn.data('mdTag'),
    cursorOffset: $toolbarBtn.data('mdCursorOffset'),
    blockTag: $toolbarBtn.data('mdBlock'),
    wrap: !$toolbarBtn.data('mdPrepend'),
    select: $toolbarBtn.data('mdSelect'),
    tagContent: $toolbarBtn.attr('data-md-tag-content'),
  });
}

export function addMarkdownListeners(form) {
  $('.markdown-area', form)
    .on('keydown', keypressNoteText)
    .on('compositionstart', compositionStartNoteText)
    .on('compositionend', compositionEndNoteText)
    .each(function attachTextareaShortcutHandlers() {
      Shortcuts.initMarkdownEditorShortcuts($(this), updateTextForToolbarBtn);
    });

  // eslint-disable-next-line @gitlab/no-global-event-off
  const $allToolbarBtns = $('.js-md', form)
    .off('click')
    .on('click', function () {
      const $toolbarBtn = $(this);

      return updateTextForToolbarBtn($toolbarBtn);
    });

  return $allToolbarBtns;
}

export function addEditorMarkdownListeners(editor) {
  // eslint-disable-next-line @gitlab/no-global-event-off
  $('.js-md')
    .off('click')
    .on('click', (e) => {
      const { mdTag, mdBlock, mdPrepend, mdSelect } = $(e.currentTarget).data();

      insertMarkdownText({
        tag: mdTag,
        blockTag: mdBlock,
        wrap: !mdPrepend,
        select: mdSelect,
        selected: editor.getSelectedText(),
        text: editor.getValue(),
        editor,
      });
      editor.focus();
    });
}

export function removeMarkdownListeners(form) {
  $('.markdown-area', form)
    .off('keydown', keypressNoteText)
    .off('compositionstart', compositionStartNoteText)
    .off('compositionend', compositionEndNoteText)
    .each(function removeTextareaShortcutHandlers() {
      Shortcuts.removeMarkdownEditorShortcuts($(this));
    });

  // eslint-disable-next-line @gitlab/no-global-event-off
  return $('.js-md', form).off('click');
}
