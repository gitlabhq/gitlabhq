/* eslint-disable class-methods-use-this */

import './lib/utils/url_utility';
import FilesCommentButton from './files_comment_button';
import SingleFileDiff from './single_file_diff';

const UNFOLD_COUNT = 20;
let isBound = false;

class Diff {
  constructor() {
    const $diffFile = $('.files .diff-file');

    $diffFile.each((index, file) => {
      if (!$.data(file, 'singleFileDiff')) {
        $.data(file, 'singleFileDiff', new SingleFileDiff(file));
      }
    });

    FilesCommentButton.init($diffFile);

    $diffFile.each((index, file) => new gl.ImageFile(file));

    if (!isBound) {
      $(document)
        .on('click', '.js-unfold', this.handleClickUnfold.bind(this))
        .on('click', '.diff-line-num a', this.handleClickLineNum.bind(this));
      isBound = true;
    }

    if (gl.utils.getLocationHash()) {
      this.highlightSelectedLine();
    }

    this.openAnchoredDiff();
  }

  handleClickUnfold(e) {
    const $target = $(e.target);
    const [oldLineNumber, newLineNumber] = this.lineNumbers($target.parent());
    const offset = newLineNumber - oldLineNumber;
    const bottom = $target.hasClass('js-unfold-bottom');
    let since;
    let to;
    let unfold = true;

    if (bottom) {
      const lineNumber = newLineNumber + 1;
      since = lineNumber;
      to = lineNumber + UNFOLD_COUNT;
    } else {
      const lineNumber = newLineNumber - 1;
      since = lineNumber - UNFOLD_COUNT;
      to = lineNumber;

      // make sure we aren't loading more than we need
      const prevNewLine = this.lineNumbers($target.parent().prev())[1];
      if (since <= prevNewLine + 1) {
        since = prevNewLine + 1;
        unfold = false;
      }
    }

    const file = $target.parents('.diff-file');
    const link = file.data('blob-diff-path');
    const view = file.data('view');

    const params = { since, to, bottom, offset, unfold, view };
    $.get(link, params, response => $target.parent().replaceWith(response));
  }

  openAnchoredDiff(cb) {
    const locationHash = gl.utils.getLocationHash();
    const anchoredDiff = locationHash && locationHash.split('_')[0];

    if (!anchoredDiff) return;

    const diffTitle = $(`#${anchoredDiff}`);
    const diffFile = diffTitle.closest('.diff-file');
    const nothingHereBlock = $('.nothing-here-block:visible', diffFile);
    if (nothingHereBlock.length) {
      const clickTarget = $('.js-file-title, .click-to-expand', diffFile);
      diffFile.data('singleFileDiff').toggleDiff(clickTarget, () => {
        this.highlightSelectedLine();
        if (cb) cb();
      });
    } else if (cb) {
      cb();
    }
  }

  handleClickLineNum(e) {
    const hash = $(e.currentTarget).attr('href');
    e.preventDefault();
    if (window.history.pushState) {
      window.history.pushState(null, null, hash);
    } else {
      window.location.hash = hash;
    }
    this.highlightSelectedLine();
  }

  diffViewType() {
    return $('.inline-parallel-buttons a.active').data('view-type');
  }

  lineNumbers(line) {
    const children = line.find('.diff-line-num').toArray();
    if (children.length !== 2) {
      return [0, 0];
    }
    return children.map(elm => parseInt($(elm).data('linenumber'), 10) || 0);
  }

  highlightSelectedLine() {
    const hash = gl.utils.getLocationHash();
    const $diffFiles = $('.diff-file');
    $diffFiles.find('.hll').removeClass('hll');

    if (hash) {
      $diffFiles
        .find(`tr#${hash}:not(.match) td, td#${hash}, td[data-line-code="${hash}"]`)
        .addClass('hll');
    }
  }
}

window.gl = window.gl || {};
window.gl.Diff = Diff;
