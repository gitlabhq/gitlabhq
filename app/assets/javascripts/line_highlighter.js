/* eslint-disable */
// LineHighlighter
//
// Handles single- and multi-line selection and highlight for blob views.
//
/*= require jquery.scrollTo */

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
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.LineHighlighter = (function() {
    // CSS class applied to highlighted lines
    LineHighlighter.prototype.highlightClass = 'hll';

    // Internal copy of location.hash so we're not dependent on `location` in tests
    LineHighlighter.prototype._hash = '';

    function LineHighlighter(hash) {
      var range;
      if (hash == null) {
        // Initialize a LineHighlighter object
        //
        // hash - String URL hash for dependency injection in tests
        hash = location.hash;
      }
      this.setHash = bind(this.setHash, this);
      this.highlightLine = bind(this.highlightLine, this);
      this.clickHandler = bind(this.clickHandler, this);
      this._hash = hash;
      this.bindEvents();
      if (hash !== '') {
        range = this.hashToRange(hash);
        if (range[0]) {
          this.highlightRange(range);
          $.scrollTo("#L" + range[0], {
            // Scroll to the first highlighted line on initial load
            // Offset -50 for the sticky top bar, and another -100 for some context
            offset: -150
          });
        }
      }
    }

    LineHighlighter.prototype.bindEvents = function() {
      $('#blob-content-holder').on('mousedown', 'a[data-line-number]', this.clickHandler);
      // While it may seem odd to bind to the mousedown event and then throw away
      // the click event, there is a method to our madness.
      //
      // If not done this way, the line number anchor will sometimes keep its
      // active state even when the event is cancelled, resulting in an ugly border
      // around the link and/or a persisted underline text decoration.
      return $('#blob-content-holder').on('click', 'a[data-line-number]', function(event) {
        return event.preventDefault();
      });
    };

    LineHighlighter.prototype.clickHandler = function(event) {
      var current, lineNumber, range;
      event.preventDefault();
      this.clearHighlight();
      lineNumber = $(event.target).closest('a').data('line-number');
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
      return $("." + this.highlightClass).removeClass(this.highlightClass);
    // Unhighlight previously highlighted lines
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
      //?L(\d+)(?:-(\d+))?$/)
      matches = hash.match(/^#?L(\d+)(?:-(\d+))?$/);
      if (matches && matches.length) {
        first = parseInt(matches[1]);
        last = matches[2] ? parseInt(matches[2]) : null;
        return [first, last];
      } else {
        return [null, null];
      }
    };

    // Highlight a single line
    //
    // lineNumber - Line number to highlight
    LineHighlighter.prototype.highlightLine = function(lineNumber) {
      return $("#LC" + lineNumber).addClass(this.highlightClass);
    };

    // Highlight all lines within a range
    //
    // range - Array containing the starting and ending line numbers
    LineHighlighter.prototype.highlightRange = function(range) {
      var i, lineNumber, ref, ref1, results;
      if (range[1]) {
        results = [];
        for (lineNumber = i = ref = range[0], ref1 = range[1]; ref <= ref1 ? i <= ref1 : i >= ref1; lineNumber = ref <= ref1 ? ++i : --i) {
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
        turbolinks: false,
        url: value
      // We're using pushState instead of assigning location.hash directly to
      // prevent the page from scrolling on the hashchange event
      }, document.title, value);
    };

    return LineHighlighter;

  })();

}).call(this);
