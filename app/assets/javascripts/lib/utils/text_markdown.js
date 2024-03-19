/* eslint-disable func-names, no-param-reassign, operator-assignment, consistent-return */
import $ from 'jquery';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { insertText } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';

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

/**
 * Returns the line of text that is before the first line
 * of the current selection
 *
 * @param {String} text - the text of the targeted text area
 * @param {Object} textArea - the targeted text area
 * @returns {String}
 */
function lineBeforeSelection(text, textArea) {
  let split = text.substring(0, textArea.selectionStart);

  split = split.split('\n');

  // Last item, at -1, is the line where the start of selection is.
  // Line before selection is therefore at -2
  const lineBefore = split[split.length - 2];

  return lineBefore === undefined ? '' : lineBefore;
}

/**
 * Returns the line of text that is after the last line
 * of the current selection
 *
 * @param {String} text - the text of the targeted text area
 * @param {Object} textArea - the targeted text area
 * @returns {String}
 */
function lineAfterSelection(text, textArea) {
  let split = text.substring(textArea.selectionEnd);

  // remove possible leading newline to get at the real line
  split = split.replace(/^\n/, '');
  split = split.split('\n');

  return split[0];
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
 * @param {Number} lineStart - start pos of first line
 * @param {Number} firstLineChange - number of characters changed on first line
 * @param {Number} totalChanged - total number of characters changed
 */
function setNewSelectionRange(
  textArea,
  selectionStart,
  selectionEnd,
  lineStart,
  firstLineChange,
  totalChanged,
) {
  let newStart = Math.max(lineStart, selectionStart + firstLineChange);
  let newEnd = Math.max(lineStart, selectionEnd + totalChanged);

  if (selectionStart === selectionEnd) {
    newEnd = newStart;
  } else if (selectionStart === lineStart) {
    newStart = lineStart;
  }

  textArea.setSelectionRange(newStart, newEnd);
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
    lineBeforeSelection(text, textArea) === blockTag &&
    lineAfterSelection(text, textArea) === blockTag;

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
    }
    if (editor) {
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

/**
 * Inserts the given MarkdownText into the given textArea or editor
 *
 * WARNING: This is a bit of legacy code that has some complicated logic.
 * There are a lot of hidden contexts to consider here. Please proceed with caution.
 *
 * We've tried to document the parameter responsibilities as best as possible.
 * Please look for actual usage in the code to verify any assumptions.
 *
 * @param {Object} options - Named parameters
 * @param {HTMLTextAreaElement} options.textArea - The relevant text area
 * @param {String} options.text - The current text of the text area
 * @param {String} options.tag - The markdown tag we want to enter (Example: `- [ ] ` for lists)
 * @param {Number} options.cursorOffset - Applied to the position after we insert the text (moves backward)
 * @param {String} options.blockTag - The markdown tag to use if a block is detected (Example ` ``` ` vs. ` ` `)
 * @param {Boolean} options.wrap - Flag for whether the tag is a wrapping tag (Example `**text**` vs `* text`)
 * @param {String} options.select - The text to select after inserting (Example `url` of `({text})[url]`)
 * @param {Object} options.editor - The instance of the SourceEditor which we are inserting MarkdownText into. This should be mutually exclusive with textArea.
 */
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
  // If we aren't really inserting anything, let's just noop.
  // Let's check for `selected` too because there might be hidden logic that actually
  // is expected to run for this case.
  if (!tag && !blockTag && !selected) {
    return;
  }

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
        const url = new URL(selected);

        if (url.origin !== 'null' || url.origin === null) {
          tag = '[text]({text})';
          select = 'text';
        }
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

  moveCursor({
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

export function updateText({ textArea, tag, cursorOffset, blockTag, wrap, select, tagContent }) {
  const $textArea = $(textArea);
  textArea = $textArea.get(0);
  const text = $textArea.val();
  const selected = selectedText(text, textArea) || tagContent;
  textArea.focus();
  insertMarkdownText({
    textArea,
    text,
    tag,
    cursorOffset,
    blockTag,
    selected,
    wrap,
    select,
  });
  textArea.click();
}

/**
 * Indents selected lines to the right by 2 spaces
 *
 * @param {Object} textArea - jQuery object with the targeted text area
 */
function indentLines($textArea) {
  const textArea = $textArea.get(0);
  const { lines, selectionStart, selectionEnd, startPos, endPos } = linesFromSelection(textArea);
  const shiftedLines = [];
  let totalAdded = 0;

  textArea.focus();
  textArea.setSelectionRange(startPos, endPos);

  lines.forEach((line) => {
    line = INDENT_CHAR.repeat(INDENT_LENGTH) + line;
    totalAdded += INDENT_LENGTH;

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
function outdentLines($textArea) {
  const textArea = $textArea.get(0);
  const { lines, selectionStart, selectionEnd, startPos, endPos } = linesFromSelection(textArea);
  const shiftedLines = [];
  let totalRemoved = 0;
  let removedFromFirstline = -1;
  let removedFromLine = 0;

  textArea.focus();
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

  if (totalRemoved > 0) insertText(textArea, textToInsert);

  setNewSelectionRange(
    textArea,
    selectionStart,
    selectionEnd,
    startPos,
    -removedFromFirstline,
    -totalRemoved,
  );
}

/* eslint-disable @gitlab/require-i18n-strings */
function handleSurroundSelectedText(e, textArea) {
  if (!gon.markdown_surround_selection) return;
  if (e.metaKey || e.ctrlKey) return;
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
 * @param {Object} listLineMatch - regex match of the current line
 * @param {Object?} nextLineMatch - regex match of the next line
 * @returns string with the new list item
 */
function continueOlText(listLineMatch, nextLineMatch) {
  const { indent, leader } = listLineMatch.groups;
  const { indent: nextIndent, isOl: nextIsOl } = nextLineMatch?.groups ?? {};

  const [numStr, postfix = ''] = leader.split('.');

  const incrementBy = nextIsOl && nextIndent === indent ? 0 : 1;
  const num = parseInt(numStr, 10) + incrementBy;

  return `${indent}${num}.${postfix}`;
}

function handleContinueList(e, textArea) {
  if (!gon.markdown_automatic_lists) return;
  if (!(e.key === 'Enter')) return;
  if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
  if (textArea.selectionStart !== textArea.selectionEnd) return;

  // prevent unintended line breaks inserted using Japanese IME on MacOS
  if (compositioningNoteText) return;

  const selectedLines = linesFromSelection(textArea);
  const firstSelectedLine = selectedLines.lines[0];
  const listLineMatch = firstSelectedLine.match(LIST_LINE_HEAD_PATTERN);

  if (listLineMatch) {
    const { leader, indent, content, isOl } = listLineMatch.groups;
    const emptyListItem = !content;
    const prefixLength = leader.length + indent.length;

    if (selectedLines.selectionStart - selectedLines.startPos < prefixLength) {
      // cursor in the indent/leader area,  allow the natural line feed to be added
      return;
    }

    if (emptyListItem) {
      // erase empty list item - select the text and allow the
      // natural line feed to erase the text
      textArea.selectionStart = textArea.selectionStart - listLineMatch[0].length;
      return;
    }

    let itemToInsert;

    // Behaviors specific to either `ol` or `ul`
    if (isOl) {
      const nextLine = lineAfterSelection(textArea.value, textArea);
      const nextLineMatch = nextLine.match(LIST_LINE_HEAD_PATTERN);

      itemToInsert = continueOlText(listLineMatch, nextLineMatch);
    } else {
      if (firstSelectedLine.match(HR_PATTERN)) return;

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
  const $textArea = $toolbarBtn.closest('.md-area').find('textarea');
  if (!$textArea.length) return;

  switch ($toolbarBtn.data('mdCommand')) {
    case 'indentLines':
      indentLines($textArea);
      break;
    case 'outdentLines':
      outdentLines($textArea);
      break;
    default:
      return updateText({
        textArea: $textArea,
        tag: $toolbarBtn.data('mdTag'),
        cursorOffset: $toolbarBtn.data('mdCursorOffset'),
        blockTag: $toolbarBtn.data('mdBlock'),
        wrap: !$toolbarBtn.data('mdPrepend'),
        select: $toolbarBtn.data('mdSelect'),
        tagContent: $toolbarBtn.attr('data-md-tag-content'),
      });
  }
}

export function addMarkdownListeners(form) {
  $('.markdown-area', form)
    .on('keydown', keypressNoteText)
    .on('compositionstart', compositionStartNoteText)
    .on('compositionend', compositionEndNoteText)
    .each(function attachTextareaShortcutHandlers() {
      Shortcuts.initMarkdownEditorShortcuts($(this), updateTextForToolbarBtn);
    });

  const $allToolbarBtns = $(form)
    .off('click', '.js-md')
    .on('click', '.js-md', function () {
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

/**
 * If the textarea cursor is positioned in a Markdown image declaration,
 * it uses the Markdown API to resolve the image’s absolute URL.
 * @param {Object} textarea Textarea DOM element
 * @param {String} markdownPreviewPath Markdown API path
 * @returns {Object} an object containing the image’s absolute URL, filename,
 * and the markdown declaration. If the textarea cursor is not positioned
 * in an image, it returns null.
 */
export const resolveSelectedImage = async (textArea, markdownPreviewPath = '') => {
  const { lines, startPos } = linesFromSelection(textArea);

  // image declarations can’t span more than one line in Markdown
  if (lines > 0) {
    return null;
  }

  const selectedLine = lines[0];

  if (!/!\[.+?\]\(.+?\)/.test(selectedLine)) return null;

  const lineSelectionStart = textArea.selectionStart - startPos;
  const preExlm = selectedLine.substring(0, lineSelectionStart).lastIndexOf('!');
  const postClose = selectedLine.substring(lineSelectionStart).indexOf(')');

  if (preExlm >= 0 && postClose >= 0) {
    const imageMarkdown = selectedLine.substring(preExlm, lineSelectionStart + postClose + 1);
    const { data } = await axios.post(markdownPreviewPath, { text: imageMarkdown });
    const parser = new DOMParser();

    const dom = parser.parseFromString(data.body, 'text/html');
    const imageURL = dom.body.querySelector('a').getAttribute('href');

    if (imageURL) {
      const filename = imageURL.substring(imageURL.lastIndexOf('/') + 1);

      return {
        imageMarkdown,
        imageURL,
        filename,
      };
    }
  }

  return null;
};
