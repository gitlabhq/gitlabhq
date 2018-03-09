/* eslint-disable import/prefer-default-export, func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, quotes, one-var, one-var-declaration-per-line, operator-assignment, no-else-return, prefer-template, prefer-arrow-callback, no-empty, max-len, consistent-return, no-unused-vars, no-return-assign, max-len, vars-on-top */

import $ from 'jquery';

const textUtils = {};

textUtils.selectedText = function(text, textarea) {
  return text.substring(textarea.selectionStart, textarea.selectionEnd);
};

textUtils.lineBefore = function(text, textarea) {
  var split;
  split = text.substring(0, textarea.selectionStart).trim().split('\n');
  return split[split.length - 1];
};

textUtils.lineAfter = function(text, textarea) {
  return text.substring(textarea.selectionEnd).trim().split('\n')[0];
};

textUtils.blockTagText = function(text, textArea, blockTag, selected) {
  var lineAfter, lineBefore;
  lineBefore = this.lineBefore(text, textArea);
  lineAfter = this.lineAfter(text, textArea);
  if (lineBefore === blockTag && lineAfter === blockTag) {
    // To remove the block tag we have to select the line before & after
    if (blockTag != null) {
      textArea.selectionStart = textArea.selectionStart - (blockTag.length + 1);
      textArea.selectionEnd = textArea.selectionEnd + (blockTag.length + 1);
    }
    return selected;
  } else {
    return blockTag + "\n" + selected + "\n" + blockTag;
  }
};

textUtils.insertText = function(textArea, text, tag, blockTag, selected, wrap) {
  var insertText, inserted, selectedSplit, startChar, removedLastNewLine, removedFirstNewLine, currentLineEmpty, lastNewLine;
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
      insertText = this.blockTagText(text, textArea, blockTag, selected);
    } else {
      insertText = selectedSplit.map(function(val) {
        if (val.indexOf(tag) === 0) {
          return "" + (val.replace(tag, ''));
        } else {
          return "" + tag + val;
        }
      }).join('\n');
    }
  } else {
    insertText = "" + startChar + tag + selected + (wrap ? tag : ' ');
  }

  if (removedFirstNewLine) {
    insertText = '\n' + insertText;
  }

  if (removedLastNewLine) {
    insertText += '\n';
  }

  if (document.queryCommandSupported('insertText')) {
    inserted = document.execCommand('insertText', false, insertText);
  }
  if (!inserted) {
    try {
      document.execCommand("ms-beginUndoUnit");
    } catch (error) {}
    textArea.value = this.replaceRange(text, textArea.selectionStart, textArea.selectionEnd, insertText);
    try {
      document.execCommand("ms-endUndoUnit");
    } catch (error) {}
  }
  return this.moveCursor(textArea, tag, wrap, removedLastNewLine);
};

textUtils.moveCursor = function(textArea, tag, wrapped, removedLastNewLine) {
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
};

textUtils.updateText = function(textArea, tag, blockTag, wrap) {
  var $textArea, selected, text;
  $textArea = $(textArea);
  textArea = $textArea.get(0);
  text = $textArea.val();
  selected = this.selectedText(text, textArea);
  $textArea.focus();
  return this.insertText(textArea, text, tag, blockTag, selected, wrap);
};

textUtils.init = function(form) {
  var self;
  self = this;
  return $('.js-md', form).off('click').on('click', function() {
    var $this;
    $this = $(this);
    return self.updateText($this.closest('.md-area').find('textarea'), $this.data('mdTag'), $this.data('mdBlock'), !$this.data('mdPrepend'));
  });
};

textUtils.removeListeners = function(form) {
  return $('.js-md', form).off('click');
};

textUtils.replaceRange = function(s, start, end, substitute) {
  return s.substring(0, start) + substitute + s.substring(end);
};

export default textUtils;
