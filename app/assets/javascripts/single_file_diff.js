/* eslint-disable consistent-return */

import $ from 'jquery';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as createFlash } from './flash';
import FilesCommentButton from './files_comment_button';
import initImageDiffHelper from './image_diff/helpers/init_image_diff';
import syntaxHighlight from './syntax_highlight';
import { spriteIcon } from '~/lib/utils/common_utils';

const WRAPPER = '<div class="diff-content"></div>';
const LOADING_HTML = '<span class="spinner"></span>';
const ERROR_HTML = `<div class="nothing-here-block">${spriteIcon(
  'warning-solid',
  's16',
)} Could not load diff</div>`;
const COLLAPSED_HTML =
  '<div class="nothing-here-block diff-collapsed">This diff is collapsed. <button class="click-to-expand btn btn-link">Click to expand it.</button></div>';

export default class SingleFileDiff {
  constructor(file) {
    this.file = file;
    this.toggleDiff = this.toggleDiff.bind(this);
    this.content = $('.diff-content', this.file);
    this.$toggleIcon = $('.diff-toggle-caret', this.file);
    this.diffForPath = this.content.find('[data-diff-for-path]').data('diffForPath');
    this.isOpen = !this.diffForPath;
    if (this.diffForPath) {
      this.collapsedContent = this.content;
      this.loadingContent = $(WRAPPER)
        .addClass('loading')
        .html(LOADING_HTML)
        .hide();
      this.content = null;
      this.collapsedContent.after(this.loadingContent);
      this.$toggleIcon.addClass('fa-caret-right');
    } else {
      this.collapsedContent = $(WRAPPER)
        .html(COLLAPSED_HTML)
        .hide();
      this.content.after(this.collapsedContent);
      this.$toggleIcon.addClass('fa-caret-down');
    }

    $('.js-file-title, .click-to-expand', this.file).on('click', e => {
      this.toggleDiff($(e.target));
    });
  }

  toggleDiff($target, cb) {
    if (
      !$target.hasClass('js-file-title') &&
      !$target.hasClass('click-to-expand') &&
      !$target.hasClass('diff-toggle-caret')
    )
      return;
    this.isOpen = !this.isOpen;
    if (!this.isOpen && !this.hasError) {
      this.content.hide();
      this.$toggleIcon.addClass('fa-caret-right').removeClass('fa-caret-down');
      this.collapsedContent.show();
    } else if (this.content) {
      this.collapsedContent.hide();
      this.content.show();
      this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
    } else {
      this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
      return this.getContentHTML(cb);
    }
  }

  getContentHTML(cb) {
    this.collapsedContent.hide();
    this.loadingContent.show();

    axios
      .get(this.diffForPath)
      .then(({ data }) => {
        this.loadingContent.hide();
        if (data.html) {
          this.content = $(data.html);
          syntaxHighlight(this.content);
        } else {
          this.hasError = true;
          this.content = $(ERROR_HTML);
        }
        this.collapsedContent.after(this.content);

        const $file = $(this.file);
        FilesCommentButton.init($file);

        const canCreateNote = $file.closest('.files').is('[data-can-create-note]');
        initImageDiffHelper.initImageDiff($file[0], canCreateNote);

        if (cb) cb();
      })
      .catch(() => {
        createFlash(__('An error occurred while retrieving diff'));
      });
  }
}
