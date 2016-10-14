(function() {
  (function(w) {
    var base;
    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).text == null) {
      base.text = {};
    }
    gl.text.randomString = function() {
      return Math.random().toString(36).substring(7);
    };
    gl.text.replaceRange = function(s, start, end, substitute) {
      return s.substring(0, start) + substitute + s.substring(end);
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
      var insertText, inserted, selectedSplit, startChar;
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
      return this.moveCursor(textArea, tag, wrap);
    };
    gl.text.moveCursor = function(textArea, tag, wrapped) {
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
    return gl.text.truncate = function(string, maxLength) {
      return string.substr(0, (maxLength - 3)) + '...';
    };
  })(window);

}).call(this);
