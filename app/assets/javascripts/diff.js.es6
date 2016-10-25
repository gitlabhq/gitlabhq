/* eslint-disable */

((global) => {
  const UNFOLD_COUNT = 20;

  class Diff {
    constructor() {
      $('.files .diff-file').singleFileDiff();
      $('.files .diff-file').filesCommentButton();

      if (this.diffViewType() === 'parallel') {
        $('.content-wrapper .container-fluid').removeClass('container-limited');
      }
      $(document)
        .off('click', '.js-unfold')
        .on('click', '.js-unfold', (event) => {
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
        })
        .off('click', '.diff-line-num a')
        .on('click', '.diff-line-num a', (event) => {
          var hash = $(event.currentTarget).attr('href');
          event.preventDefault();
          if ( history.pushState ) {
            history.pushState(null, null, hash);
          } else {
            window.location.hash = hash;
          }
          this.highlighSelectedLine();
        });

      this.highlighSelectedLine();
    }

    diffViewType() {
      return $('.inline-parallel-buttons a.active').data('view-type');
    }

    lineNumbers(line) {
      if (!line.children().length) {
        return [0, 0];
      }

      return line.find('.diff-line-num').map(function() {
        return parseInt($(this).data('linenumber'));
      });
    }

    highlighSelectedLine() {
      const $diffFiles = $('.diff-file');
      $diffFiles.find('.hll').removeClass('hll');

      if (window.location.hash !== '') {
        const hash = window.location.hash.replace('#', '');
        $diffFiles
          .find(`tr#${hash}:not(.match) td, td#${hash}, td[data-line-code="${hash}"]`)
          .addClass('hll');
      }
    }
  }

  global.Diff = Diff;

})(window.gl || (window.gl = {}));
