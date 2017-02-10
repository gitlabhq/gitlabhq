/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, quotes, one-var, one-var-declaration-per-line, operator-assignment, no-else-return, prefer-template, prefer-arrow-callback, no-empty, max-len, consistent-return, no-unused-vars, no-return-assign, max-len */

require('vendor/latinise');

(function() {
  (function(w) {
    var base;
    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).text == null) {
      base.text = {};
    }
    gl.text.addDelimiter = function(text) {
      return text ? text.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") : text;
    };
    gl.text.randomString = function() {
      return Math.random().toString(36).substring(7);
    };
    gl.text.replaceRange = function(s, start, end, substitute) {
      return s.substring(0, start) + substitute + s.substring(end);
    };
    gl.text.getTextWidth = function(text, font) {
      /**
      * Uses canvas.measureText to compute and return the width of the given text of given font in pixels.
      *
      * @param {String} text The text to be rendered.
      * @param {String} font The css font descriptor that text is to be rendered with (e.g. "bold 14px verdana").
      *
      * @see http://stackoverflow.com/questions/118241/calculate-text-width-with-javascript/21015393#21015393
      */
      // re-use canvas object for better performance
      var canvas = gl.text.getTextWidth.canvas || (gl.text.getTextWidth.canvas = document.createElement('canvas'));
      var context = canvas.getContext('2d');
      context.font = font;
      return context.measureText(text).width;
    };
    gl.text.selectedText = function(text, textarea) {
      return text.substring(textarea.selectionStart, textarea.selectionEnd);
    };
    gl.text.lineBefore = function(text, textarea) {
      var split;
      split = text.substring(0, textarea.selectionStart).trim().split('\n');
      return split[split.length - 1];
    };
    gl.text.lineAfter = function(text, textarea) {
      return text.substring(textarea.selectionEnd).trim().split('\n')[0];
    };
    gl.text.blockTagText = function(text, textArea, blockTag, selected) {
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
    gl.text.insertText = function(textArea, text, tag, blockTag, selected, wrap) {
      var insertText, inserted, selectedSplit, startChar, removedLastNewLine, removedFirstNewLine;
      removedLastNewLine = false;
      removedFirstNewLine = false;

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
      startChar = !wrap && textArea.selectionStart > 0 ? '\n' : '';

      if (selectedSplit.length > 1 && (!wrap || (blockTag != null))) {
        if (blockTag != null) {
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
    gl.text.moveCursor = function(textArea, tag, wrapped, removedLastNewLine) {
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
    gl.text.updateText = function(textArea, tag, blockTag, wrap) {
      var $textArea, oldVal, selected, text;
      $textArea = $(textArea);
      oldVal = $textArea.val();
      textArea = $textArea.get(0);
      text = $textArea.val();
      selected = this.selectedText(text, textArea);
      $textArea.focus();
      return this.insertText(textArea, text, tag, blockTag, selected, wrap);
    };
    gl.text.init = function(form) {
      var self;
      self = this;
      return $('.js-md', form).off('click').on('click', function() {
        var $this;
        $this = $(this);
        return self.updateText($this.closest('.md-area').find('textarea'), $this.data('md-tag'), $this.data('md-block'), !$this.data('md-prepend'));
      });
    };
    gl.text.removeListeners = function(form) {
      return $('.js-md', form).off();
    };
    gl.text.humanize = function(string) {
      return string.charAt(0).toUpperCase() + string.replace(/_/g, ' ').slice(1);
    };
    gl.text.pluralize = function(str, count) {
      return str + (count > 1 || count === 0 ? 's' : '');
    };
    gl.text.truncate = function(string, maxLength) {
      return string.substr(0, (maxLength - 3)) + '...';
    };
    gl.text.dasherize = function(str) {
      return str.replace(/[_\s]+/g, '-');
    };
    gl.text.slugify = function(str) {
      return str.trim().toLowerCase().latinise();
    };
  })(window);
}).call(this);
