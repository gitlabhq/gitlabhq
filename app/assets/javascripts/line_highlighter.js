/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-use-before-define, no-underscore-dangle, no-param-reassign, prefer-template, quotes, comma-dangle, prefer-arrow-callback, consistent-return, one-var, one-var-declaration-per-line, no-else-return, max-len */

import $ from 'jquery';

// LineHighlighter
//
// Handles single- and multi-line selection and highlight for blob views.
//
//
// ### Example Markup
//
//   <div id="blob-content-holder">
//     <div class="file-content">
//       <div class="line-numbers">
//         <a href="#L1" id="L1" data-line-number="1">1</a>
//         <a href="#L2" id="L2" data-line-number="2">2</a>
//         <a href="#L3" id="L3" data-line-number="3">3</a>
//         <a href="#L4" id="L4" data-line-number="4">4</a>
//         <a href="#L5" id="L5" data-line-number="5">5</a>
//       </div>
//       <pre class="code highlight">
//         <code>
//           <span id="LC1" class="line">...</span>
//           <span id="LC2" class="line">...</span>
//           <span id="LC3" class="line">...</span>
//           <span id="LC4" class="line">...</span>
//           <span id="LC5" class="line">...</span>
//         </code>
//       </pre>
//     </div>
//   </div>
//

const LineHighlighter = function(options = {}) {
  options.highlightLineClass = options.highlightLineClass || 'hll';
  options.fileHolderSelector = options.fileHolderSelector || '.file-holder';
  options.scrollFileHolder = options.scrollFileHolder || false;
  options.hash = options.hash || location.hash;

  this.options = options;
  this._hash = options.hash;
  this.highlightLineClass = options.highlightLineClass;
  this.setHash = this.setHash.bind(this);
  this.highlightLine = this.highlightLine.bind(this);
  this.clickHandler = this.clickHandler.bind(this);
  this.highlightHash = this.highlightHash.bind(this);

  this.bindEvents();
  this.highlightHash();
};

LineHighlighter.prototype.bindEvents = function() {
  const $fileHolder = $(this.options.fileHolderSelector);

  $fileHolder.on('click', 'a[data-line-number]', this.clickHandler);
  $fileHolder.on('highlight:line', this.highlightHash);
};

LineHighlighter.prototype.highlightHash = function(newHash) {
  let range;
  if (newHash && typeof newHash === 'string') this._hash = newHash;

  this.clearHighlight();

  if (this._hash !== '') {
    range = this.hashToRange(this._hash);
    if (range[0]) {
      this.highlightRange(range);
      const lineSelector = `#L${range[0]}`;
      const scrollOptions = {
        // Scroll to the first highlighted line on initial load
        // Offset -50 for the sticky top bar, and another -100 for some context
        offset: -150
      };
      if (this.options.scrollFileHolder) {
        $(this.options.fileHolderSelector).scrollTo(lineSelector, scrollOptions);
      } else {
        $.scrollTo(lineSelector, scrollOptions);
      }
    }
  }
};

LineHighlighter.prototype.clickHandler = function(event) {
  var current, lineNumber, range;
  event.preventDefault();
  this.clearHighlight();
  lineNumber = $(event.target).closest('a').data('lineNumber');
  current = this.hashToRange(this._hash);
  if (!(current[0] && event.shiftKey)) {
    // If there's no current selection, or there is but Shift wasn't held,
    // treat this like a single-line selection.
    this.setHash(lineNumber);
    return this.highlightLine(lineNumber);
  } else if (event.shiftKey) {
    if (lineNumber < current[0]) {
      range = [lineNumber, current[0]];
    } else {
      range = [current[0], lineNumber];
    }
    this.setHash(range[0], range[1]);
    return this.highlightRange(range);
  }
};

LineHighlighter.prototype.clearHighlight = function() {
  return $("." + this.highlightLineClass).removeClass(this.highlightLineClass);
};

// Convert a URL hash String into line numbers
//
// hash - Hash String
//
// Examples:
//
//   hashToRange('#L5')    # => [5, null]
//   hashToRange('#L5-15') # => [5, 15]
//   hashToRange('#foo')   # => [null, null]
//
// Returns an Array
LineHighlighter.prototype.hashToRange = function(hash) {
  var first, last, matches;
  // ?L(\d+)(?:-(\d+))?$/)
  matches = hash.match(/^#?L(\d+)(?:-(\d+))?$/);
  if (matches && matches.length) {
    first = parseInt(matches[1], 10);
    last = matches[2] ? parseInt(matches[2], 10) : null;
    return [first, last];
  } else {
    return [null, null];
  }
};

// Highlight a single line
//
// lineNumber - Line number to highlight
LineHighlighter.prototype.highlightLine = function(lineNumber) {
  return $("#LC" + lineNumber).addClass(this.highlightLineClass);
};

// Highlight all lines within a range
//
// range - Array containing the starting and ending line numbers
LineHighlighter.prototype.highlightRange = function(range) {
  var i, lineNumber, ref, ref1, results;
  if (range[1]) {
    results = [];
    for (lineNumber = i = ref = range[0], ref1 = range[1]; ref <= ref1 ? i <= ref1 : i >= ref1; lineNumber = ref <= ref1 ? (i += 1) : (i -= 1)) {
      results.push(this.highlightLine(lineNumber));
    }
    return results;
  } else {
    return this.highlightLine(range[0]);
  }
};

// Set the URL hash string
LineHighlighter.prototype.setHash = function(firstLineNumber, lastLineNumber) {
  var hash;
  if (lastLineNumber) {
    hash = "#L" + firstLineNumber + "-" + lastLineNumber;
  } else {
    hash = "#L" + firstLineNumber;
  }
  this._hash = hash;
  return this.__setLocationHash__(hash);
};

// Make the actual hash change in the browser
//
// This method is stubbed in tests.
LineHighlighter.prototype.__setLocationHash__ = function(value) {
  return history.pushState({
    url: value
  // We're using pushState instead of assigning location.hash directly to
  // prevent the page from scrolling on the hashchange event
  }, document.title, value);
};

export default LineHighlighter;
