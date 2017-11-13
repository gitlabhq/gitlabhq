/**
 * Adds a , to a string composed by numbers, at every 3 chars.
 *
 * 2333 -> 2,333
 * 232324 -> 232,324
 *
 * @param {String} text
 * @returns {String}
 */
export const addDelimiter = text => (text ? text.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') : text);

/**
 * Returns '99+' for numbers bigger than 99.
 *
 * @param {Number} count
 * @return {Number|String}
 */
<<<<<<< HEAD
export function highCountTrim(count) {
  return count > 99 ? '99+' : count;
}

export function capitalizeFirstCharacter(text) {
  return `${text[0].toUpperCase()}${text.slice(1)}`;
}

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
=======
export const highCountTrim = count => (count > 99 ? '99+' : count);
>>>>>>> ce-com/master

/**
 * Converst first char to uppercase and replaces undercores with spaces
 * @param {String} string
 * @requires {String}
 */
export const humanize = string => string.charAt(0).toUpperCase() + string.replace(/_/g, ' ').slice(1);

/**
 * Adds an 's' to the end of the string when count is bigger than 0
 * @param {String} str
 * @param {Number} count
 * @returns {String}
 */
export const pluralize = (str, count) => str + (count > 1 || count === 0 ? 's' : '');

/**
 * Replaces underscores with dashes
 * @param {*} str
 * @returns {String}
 */
export const dasherize = str => str.replace(/[_\s]+/g, '-');

/**
 * Removes accents and converts to lower case
 * @param {String} str
 * @returns {String}
 */
export const slugify = str => str.trim().toLowerCase();

/**
 * Truncates given text
 *
 * @param {String} string
 * @param {Number} maxLength
 * @returns {String}
 */
export const truncate = (string, maxLength) => `${string.substr(0, (maxLength - 3))}...`;

