/* eslint-disable consistent-return */

import $ from 'jquery';
import { spriteIcon } from '~/lib/utils/common_utils';
import FilesCommentButton from './files_comment_button';
import createFlash from './flash';
import initImageDiffHelper from './image_diff/helpers/init_image_diff';
import axios from './lib/utils/axios_utils';
import { __ } from './locale';
import syntaxHighlight from './syntax_highlight';

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
    this.$chevronRightIcon = $('.diff-toggle-caret .chevron-right', this.file);
    this.$chevronDownIcon = $('.diff-toggle-caret .chevron-down', this.file);
    this.diffForPath = this.content.find('[data-diff-for-path]').data('diffForPath');
    this.isOpen = !this.diffForPath;
    if (this.diffForPath) {
      this.collapsedContent = this.content;
      this.loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide();
      this.content = null;
      this.collapsedContent.after(this.loadingContent);
      this.$chevronRightIcon.removeClass('gl-display-none');
    } else {
      this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
      this.content.after(this.collapsedContent);
      this.$chevronDownIcon.removeClass('gl-display-none');
    }

    $('.js-file-title, .click-to-expand', this.file).on('click', (e) => {
      this.toggleDiff($(e.target));
    });
  }

  toggleDiff($target, cb) {
    if (
      !$target.hasClass('js-file-title') &&
      !$target.hasClass('click-to-expand') &&
      !$target.closest('.diff-toggle-caret').length > 0
    )
      return;
    this.isOpen = !this.isOpen;
    if (!this.isOpen && !this.hasError) {
      this.content.hide();
      this.$chevronRightIcon.removeClass('gl-display-none');
      this.$chevronDownIcon.addClass('gl-display-none');
      this.collapsedContent.show();
    } else if (this.content) {
      this.collapsedContent.hide();
      this.content.show();
      this.$chevronDownIcon.removeClass('gl-display-none');
      this.$chevronRightIcon.addClass('gl-display-none');
    } else {
      this.$chevronDownIcon.removeClass('gl-display-none');
      this.$chevronRightIcon.addClass('gl-display-none');
      return this.getContentHTML(cb);
    }
  }

  getContentHTML(cb) {
    this.collapsedContent.hide();
    this.loadingContent.show();

    return axios
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
        createFlash({
          message: __('An error occurred while retrieving diff'),
        });
      });
  }
}
