/* eslint-disable import/prefer-default-export, func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, quotes, one-var, one-var-declaration-per-line, operator-assignment, no-else-return, prefer-template, prefer-arrow-callback, no-empty, max-len, consistent-return, no-unused-vars, no-return-assign, max-len, vars-on-top */
import $ from 'jquery';
import { insertText } from '~/lib/utils/common_utils';

function selectedText(text, textarea) {
  return text.substring(textarea.selectionStart, textarea.selectionEnd);
}

function lineBefore(text, textarea) {
  var split;
  split = text.substring(0, textarea.selectionStart).trim().split('\n');
  return split[split.length - 1];
}

function lineAfter(text, textarea) {
  return text.substring(textarea.selectionEnd).trim().split('\n')[0];
}

function blockTagText(text, textArea, blockTag, selected) {
  const before = lineBefore(text, textArea);
  const after = lineAfter(text, textArea);
  if (before === blockTag && after === blockTag) {
    // To remove the block tag we have to select the line before & after
    if (blockTag != null) {
      textArea.selectionStart = textArea.selectionStart - (blockTag.length + 1);
      textArea.selectionEnd = textArea.selectionEnd + (blockTag.length + 1);
    }
    return selected;
  } else {
    return blockTag + "\n" + selected + "\n" + blockTag;
  }
}

function moveCursor(textArea, tag, wrapped, removedLastNewLine) {
  var pos;
  if (!textArea.setSelectionRange) {
    return;
  }
  if (textArea.selectionStart === textArea.selectionEnd) {
    if (wrapped) {
      pos = textArea.selectionStart - tag.length;
    } else {
      pos = textArea.selectionStart;
    }

    if (removedLastNewLine) {
      pos -= 1;
    }

    return textArea.setSelectionRange(pos, pos);
  }
}

export function insertMarkdownText(textArea, text, tag, blockTag, selected, wrap) {
  var textToInsert, inserted, selectedSplit, startChar, removedLastNewLine, removedFirstNewLine, currentLineEmpty, lastNewLine;
  removedLastNewLine = false;
  removedFirstNewLine = false;
  currentLineEmpty = false;

  // Remove the first newline
  if (selected.indexOf('\n') === 0) {
    removedFirstNewLine = true;
    selected = selected.replace(/\n+/, '');
  }

  // Remove the last newline
  if (textArea.selectionEnd - textArea.selectionStart > selected.replace(/\n$/, '').length) {
    removedLastNewLine = true;
    selected = selected.replace(/\n$/, '');
  }

  selectedSplit = selected.split('\n');

  if (!wrap) {
    lastNewLine = textArea.value.substr(0, textArea.selectionStart).lastIndexOf('\n');

    // Check whether the current line is empty or consists only of spaces(=handle as empty)
    if (/^\s*$/.test(textArea.value.substring(lastNewLine, textArea.selectionStart))) {
      currentLineEmpty = true;
    }
  }

  startChar = !wrap && !currentLineEmpty && textArea.selectionStart > 0 ? '\n' : '';

  if (selectedSplit.length > 1 && (!wrap || (blockTag != null && blockTag !== ''))) {
    if (blockTag != null && blockTag !== '') {
      textToInsert = blockTagText(text, textArea, blockTag, selected);
    } else {
      textToInsert = selectedSplit.map(function(val) {
        if (val.indexOf(tag) === 0) {
          return "" + (val.replace(tag, ''));
        } else {
          return "" + tag + val;
        }
      }).join('\n');
    }
  } else {
    textToInsert = "" + startChar + tag + selected + (wrap ? tag : ' ');
  }

  if (removedFirstNewLine) {
    textToInsert = '\n' + textToInsert;
  }

  if (removedLastNewLine) {
    textToInsert += '\n';
  }

  insertText(textArea, textToInsert);
  return moveCursor(textArea, tag, wrap, removedLastNewLine);
}

function updateText(textArea, tag, blockTag, wrap) {
  var $textArea, selected, text;
  $textArea = $(textArea);
  textArea = $textArea.get(0);
  text = $textArea.val();
  selected = selectedText(text, textArea);
  $textArea.focus();
  return insertMarkdownText(textArea, text, tag, blockTag, selected, wrap);
}

function replaceRange(s, start, end, substitute) {
  return s.substring(0, start) + substitute + s.substring(end);
}

export function addMarkdownListeners(form) {
  return $('.js-md', form).off('click').on('click', function() {
    const $this = $(this);
    return updateText($this.closest('.md-area').find('textarea'), $this.data('mdTag'), $this.data('mdBlock'), !$this.data('mdPrepend'));
  });
}

export function removeMarkdownListeners(form) {
  return $('.js-md', form).off('click');
}
