
/*= require jquery.scrollTo */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.LineHighlighter = (function() {
    LineHighlighter.prototype.highlightClass = 'hll';

    LineHighlighter.prototype._hash = '';

    function LineHighlighter(hash) {
      var range;
      if (hash == null) {
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
            offset: -150
          });
        }
      }
    }

    LineHighlighter.prototype.bindEvents = function() {
      $('#blob-content-holder').on('mousedown', 'a[data-line-number]', this.clickHandler);
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
    };

    LineHighlighter.prototype.hashToRange = function(hash) {
      var first, last, matches;
      matches = hash.match(/^#?L(\d+)(?:-(\d+))?$/);
      if (matches && matches.length) {
        first = parseInt(matches[1]);
        last = matches[2] ? parseInt(matches[2]) : null;
        return [first, last];
      } else {
        return [null, null];
      }
    };

    LineHighlighter.prototype.highlightLine = function(lineNumber) {
      return $("#LC" + lineNumber).addClass(this.highlightClass);
    };

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

    LineHighlighter.prototype.__setLocationHash__ = function(value) {
      return history.pushState({
        turbolinks: false,
        url: value
      }, document.title, value);
    };

    return LineHighlighter;

  })();

}).call(this);
