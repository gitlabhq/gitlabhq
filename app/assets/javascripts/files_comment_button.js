/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, max-len, one-var, one-var-declaration-per-line, quotes, prefer-template, newline-per-chained-call, comma-dangle, new-cap, no-else-return, consistent-return */
/* global FilesCommentButton */
/* global notes */

window.FilesCommentButton = (function() {
  var COMMENT_BUTTON_CLASS, EMPTY_CELL_CLASS, LINE_COLUMN_CLASSES, LINE_CONTENT_CLASS, LINE_HOLDER_CLASS, LINE_NUMBER_CLASS, OLD_LINE_CLASS, TEXT_FILE_SELECTOR, UNFOLDABLE_LINE_CLASS;

  COMMENT_BUTTON_CLASS = '.add-diff-note';

  LINE_HOLDER_CLASS = '.line_holder';

  LINE_NUMBER_CLASS = 'diff-line-num';

  LINE_CONTENT_CLASS = 'line_content';

  UNFOLDABLE_LINE_CLASS = 'js-unfold';

  EMPTY_CELL_CLASS = 'empty-cell';

  OLD_LINE_CLASS = 'old_line';

  LINE_COLUMN_CLASSES = "." + LINE_NUMBER_CLASS + ", .line_content";

  TEXT_FILE_SELECTOR = '.text-file';

  function FilesCommentButton(filesContainerElement) {
    this.render = this.render.bind(this);
    this.hideButton = this.hideButton.bind(this);
    this.isParallelView = notes.isParallelView();
    filesContainerElement.on('mouseover', LINE_COLUMN_CLASSES, this.render)
      .on('mouseleave', LINE_COLUMN_CLASSES, this.hideButton);
  }

  FilesCommentButton.prototype.render = function(e) {
    const $currentTarget = $(e.currentTarget);
    const buttonParentElement = this.getButtonParent($currentTarget);

    if (!this.validateButtonParent(buttonParentElement)) return;

    $button = $(COMMENT_BUTTON_CLASS, buttonParentElement);
    buttonParentElement.addClass('is-over')
      .nextUntil(`.${LINE_CONTENT_CLASS}`).addClass('is-over');
  };

  FilesCommentButton.prototype.hideButton = function(e) {
    var $currentTarget = $(e.currentTarget);
    var buttonParentElement = this.getButtonParent($currentTarget);

    buttonParentElement.removeClass('is-over')
      .nextUntil(`.${LINE_CONTENT_CLASS}`).removeClass('is-over');
  };

  FilesCommentButton.prototype.getButtonParent = function(hoveredElement) {
    if (!this.isParallelView) {
      if (hoveredElement.hasClass(OLD_LINE_CLASS)) {
        return hoveredElement;
      }
      return hoveredElement.parent().find("." + OLD_LINE_CLASS);
    } else {
      if (hoveredElement.hasClass(LINE_NUMBER_CLASS)) {
        return hoveredElement;
      }
      return $(hoveredElement).prev("." + LINE_NUMBER_CLASS);
    }
  };

  FilesCommentButton.prototype.validateButtonParent = function(buttonParentElement) {
    return !buttonParentElement.hasClass(EMPTY_CELL_CLASS) && !buttonParentElement.hasClass(UNFOLDABLE_LINE_CLASS);
  };

  return FilesCommentButton;
})();

$.fn.filesCommentButton = function() {
  if (!(this && (this.parent().data('can-create-note') != null))) {
    return;
  }
  return this.each(function() {
    if (!$.data(this, 'filesCommentButton')) {
      return $.data(this, 'filesCommentButton', new FilesCommentButton($(this)));
    }
  });
};
