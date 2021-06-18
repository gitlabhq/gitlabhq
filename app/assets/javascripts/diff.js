import $ from 'jquery';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import FilesCommentButton from './files_comment_button';
import initImageDiffHelper from './image_diff/helpers/init_image_diff';
import { getLocationHash } from './lib/utils/url_utility';
import SingleFileDiff from './single_file_diff';

const UNFOLD_COUNT = 20;
let isBound = false;

export default class Diff {
  constructor() {
    const $diffFile = $('.files .diff-file');

    $diffFile.each((index, file) => {
      if (!$.data(file, 'singleFileDiff')) {
        $.data(file, 'singleFileDiff', new SingleFileDiff(file));
      }
    });

    const tab = document.getElementById('diffs');
    if (!tab || (tab && tab.dataset && tab.dataset.isLocked !== ''))
      FilesCommentButton.init($diffFile);

    const firstFile = $('.files').first().get(0);
    const canCreateNote = firstFile && firstFile.hasAttribute('data-can-create-note');
    $diffFile.each((index, file) => initImageDiffHelper.initImageDiff(file, canCreateNote));

    if (!isBound) {
      $(document)
        .on('click', '.js-unfold', this.handleClickUnfold.bind(this))
        .on('click', '.diff-line-num a', this.handleClickLineNum.bind(this))
        .on('mousedown', 'td.line_content.parallel', this.handleParallelLineDown.bind(this));
      isBound = true;
    }

    if (getLocationHash()) {
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
    const link = file.data('blobDiffPath');
    const view = file.data('view');

    const params = { since, to, bottom, offset, unfold, view };
    axios
      .get(link, { params })
      .then(({ data }) => $target.parent().replaceWith(data))
      .catch(() =>
        createFlash({
          message: __('An error occurred while loading diff'),
        }),
      );
  }

  openAnchoredDiff(cb) {
    const locationHash = getLocationHash();
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
  // eslint-disable-next-line class-methods-use-this
  handleParallelLineDown(e) {
    const line = $(e.currentTarget);
    const table = line.closest('table');

    table.removeClass('left-side-selected right-side-selected');

    const lineClass = ['left-side', 'right-side'].filter((name) => line.hasClass(name))[0];
    if (lineClass) {
      table.addClass(`${lineClass}-selected`);
    }
  }
  // eslint-disable-next-line class-methods-use-this
  diffViewType() {
    return $('.inline-parallel-buttons a.active').data('viewType');
  }
  // eslint-disable-next-line class-methods-use-this
  lineNumbers(line) {
    const children = line.find('.diff-line-num').toArray();
    if (children.length !== 2) {
      return [0, 0];
    }
    return children.map((elm) => parseInt($(elm).data('linenumber'), 10) || 0);
  }
  // eslint-disable-next-line class-methods-use-this
  highlightSelectedLine() {
    const hash = getLocationHash();
    const $diffFiles = $('.diff-file');
    $diffFiles.find('.hll').removeClass('hll');

    if (hash) {
      $diffFiles
        .find(`tr#${hash}:not(.match) td, td#${hash}, td[data-line-code="${hash}"]`)
        .addClass('hll');
    }
  }
}
