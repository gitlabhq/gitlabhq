/* eslint-disable func-names, prefer-arrow-callback, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, one-var-declaration-per-line, consistent-return, no-param-reassign, max-len */

import $ from 'jquery';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import createFlash from './flash';
import FilesCommentButton from './files_comment_button';
import imageDiffHelper from './image_diff/helpers/index';
import syntaxHighlight from './syntax_highlight';

const WRAPPER = '<div class="diff-content"></div>';
const LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>';
const ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>';
const COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. <a class="click-to-expand">Click to expand it.</a></div>';

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
      this.loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide();
      this.content = null;
      this.collapsedContent.after(this.loadingContent);
      this.$toggleIcon.addClass('fa-caret-right');
    } else {
      this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
      this.content.after(this.collapsedContent);
      this.$toggleIcon.addClass('fa-caret-down');
    }

    $('.js-file-title, .click-to-expand', this.file).on('click', (function (e) {
      this.toggleDiff($(e.target));
    }).bind(this));
  }

  toggleDiff($target, cb) {
    if (!$target.hasClass('js-file-title') && !$target.hasClass('click-to-expand') && !$target.hasClass('diff-toggle-caret')) return;
    this.isOpen = !this.isOpen;
    if (!this.isOpen && !this.hasError) {
      this.content.hide();
      this.$toggleIcon.addClass('fa-caret-right').removeClass('fa-caret-down');
      this.collapsedContent.show();
      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        gl.diffNotesCompileComponents();
      }
    } else if (this.content) {
      this.collapsedContent.hide();
      this.content.show();
      this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
      if (typeof gl.diffNotesCompileComponents !== 'undefined') {
        gl.diffNotesCompileComponents();
      }
    } else {
      this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
      return this.getContentHTML(cb);
    }
  }

  getContentHTML(cb) {
    this.collapsedContent.hide();
    this.loadingContent.show();

    axios.get(this.diffForPath)
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

        if (typeof gl.diffNotesCompileComponents !== 'undefined') {
          gl.diffNotesCompileComponents();
        }

        const $file = $(this.file);
        FilesCommentButton.init($file);

        const canCreateNote = $file.closest('.files').is('[data-can-create-note]');
        imageDiffHelper.initImageDiff($file[0], canCreateNote);

        if (cb) cb();
      })
      .catch(() => {
        createFlash(__('An error occurred while retrieving diff'));
      });
  }
}
