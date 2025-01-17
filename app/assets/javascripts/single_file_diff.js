import $ from 'jquery';
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';
import { renderVueComponentForLegacyJS } from '~/render_vue_component_for_legacy_js';
import { spriteIcon } from '~/lib/utils/common_utils';
import FilesCommentButton from './files_comment_button';
import initImageDiffHelper from './image_diff/helpers/init_image_diff';
import axios from './lib/utils/axios_utils';
import { __ } from './locale';
import syntaxHighlight from './syntax_highlight';

const WRAPPER = '<div class="diff-content"></div>';
const LOADING_HTML = loadingIconForLegacyJS().outerHTML;
const ERROR_HTML = `<div class="nothing-here-block">${spriteIcon(
  'warning-solid',
  's16',
)} Could not load diff</div>`;
const CLICK_TO_EXPAND_BUTTON_HTML = renderVueComponentForLegacyJS(
  GlButton,
  {
    class: 'click-to-expand',
    props: { variant: 'link' },
  },
  __('Click to expand it.'),
).outerHTML;
const COLLAPSED_HTML = `<div class="nothing-here-block diff-collapsed">${__('This diff is collapsed.')} ${CLICK_TO_EXPAND_BUTTON_HTML}</div>`;

export default class SingleFileDiff {
  constructor(file) {
    this.file = file;
    this.toggleDiff = this.toggleDiff.bind(this);
    this.content = $('.diff-content', this.file);
    this.$chevronRightIcon = $('.diff-toggle-caret .chevron-right', this.file);
    this.$chevronDownIcon = $('.diff-toggle-caret .chevron-down', this.file);
    this.diffForPath = this.content
      .find('div:not(.note-text)[data-diff-for-path]')
      .data('diffForPath');
    this.isOpen = !this.diffForPath;
    if (this.diffForPath) {
      this.collapsedContent = this.content;
      this.loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide();
      this.content = null;
      this.collapsedContent.after(this.loadingContent);
      this.$chevronRightIcon.removeClass('gl-hidden');
    } else {
      this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
      this.content.after(this.collapsedContent);
      this.$chevronDownIcon.removeClass('gl-hidden');
    }

    $('.js-file-title', this.file).on('click', (e) => {
      this.toggleDiff($(e.target));
    });
    $('.click-to-expand', this.file).on('click', (e) => {
      this.toggleDiff($(e.currentTarget));
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
      this.$chevronRightIcon.removeClass('gl-hidden');
      this.$chevronDownIcon.addClass('gl-hidden');
      this.collapsedContent.show();
    } else if (this.content) {
      this.collapsedContent.hide();
      this.content.show();
      this.$chevronDownIcon.removeClass('gl-hidden');
      this.$chevronRightIcon.addClass('gl-hidden');
    } else {
      this.$chevronDownIcon.removeClass('gl-hidden');
      this.$chevronRightIcon.addClass('gl-hidden');
      return this.getContentHTML(cb); // eslint-disable-line consistent-return
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
        createAlert({
          message: __('An error occurred while retrieving diff'),
        });
      });
  }
}
