/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, max-len, one-var, camelcase, one-var-declaration-per-line, no-unused-vars, no-unused-expressions, no-sequences, object-shorthand, comma-dangle, prefer-arrow-callback, semi, radix, padded-blocks, max-len */
(function() {
  this.Diff = (function() {
    var UNFOLD_COUNT;

    UNFOLD_COUNT = 20;

    function Diff() {
      $('.files .diff-file').singleFileDiff();
      this.filesCommentButton = $('.files .diff-file').filesCommentButton();
      if (this.diffViewType() === 'parallel') {
        $('.content-wrapper .container-fluid').removeClass('container-limited');
      }
      $(document)
        .off('click', '.js-unfold')
        .on('click', '.js-unfold', (function(event) {
          var line_number, link, file, offset, old_line, params, prev_new_line, prev_old_line, ref, ref1, since, target, to, unfold, unfoldBottom;
          target = $(event.target);
          unfoldBottom = target.hasClass('js-unfold-bottom');
          unfold = true;
          ref = this.lineNumbers(target.parent()), old_line = ref[0], line_number = ref[1];
          offset = line_number - old_line;
          if (unfoldBottom) {
            line_number += 1;
            since = line_number;
            to = line_number + UNFOLD_COUNT;
          } else {
            ref1 = this.lineNumbers(target.parent().prev()), prev_old_line = ref1[0], prev_new_line = ref1[1];
            line_number -= 1;
            to = line_number;
            if (line_number - UNFOLD_COUNT > prev_new_line + 1) {
              since = line_number - UNFOLD_COUNT;
            } else {
              since = prev_new_line + 1;
              unfold = false;
            }
          }
          file = target.parents('.diff-file');
          link = file.data('blob-diff-path');
          params = {
            since: since,
            to: to,
            bottom: unfoldBottom,
            offset: offset,
            unfold: unfold,
            view: file.data('view')
          };
          return $.get(link, params, function(response) {
            return target.parent().replaceWith(response);
          });
        }).bind(this));

      $(document)
        .off('click', '.diff-line-num a')
        .on('click', '.diff-line-num a', (function(e) {
          var hash = $(e.currentTarget).attr('href');
          e.preventDefault();
          if ( history.pushState ) {
            history.pushState(null, null, hash);
          } else {
            window.location.hash = hash;
          }
          this.highlighSelectedLine();
        }).bind(this));

      this.highlighSelectedLine();
    }

    Diff.prototype.diffViewType = function() {
      return $('.inline-parallel-buttons a.active').data('view-type');
    }

    Diff.prototype.lineNumbers = function(line) {
      if (!line.children().length) {
        return [0, 0];
      }

      return line.find('.diff-line-num').map(function() {
        return parseInt($(this).data('linenumber'));
      });
    };

    Diff.prototype.highlighSelectedLine = function() {
      var $diffLine, dataLineString, locationHash;
      $('.hll').removeClass('hll');
      locationHash = window.location.hash;
      if (locationHash !== '') {
        dataLineString = '[data-line-code="' + locationHash.replace('#', '') + '"]';
        $diffLine = $(".diff-file " + locationHash + ":not(.match)");
        if (!$diffLine.is('tr')) {
          $diffLine = $(".diff-file td" + locationHash + ", .diff-file td" + dataLineString);
        } else {
          $diffLine = $diffLine.find('td');
        }
        $diffLine.addClass('hll');
      }
    };

    return Diff;

  })();

}).call(this);
