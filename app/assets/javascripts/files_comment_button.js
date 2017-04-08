/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, max-len, one-var, one-var-declaration-per-line, quotes, prefer-template, newline-per-chained-call, comma-dangle, new-cap, no-else-return, consistent-return */
/* global FilesCommentButton */
/* global notes */

let $commentButtonTemplate;
var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

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
    this.render = bind(this.render, this);
    this.hideButton = bind(this.hideButton, this);
    this.isParallelView = notes.isParallelView();
    filesContainerElement.on('mouseover', LINE_COLUMN_CLASSES, this.render)
      .on('mouseleave', LINE_COLUMN_CLASSES, this.hideButton);
  }

  FilesCommentButton.prototype.render = function(e) {
    var $currentTarget, buttonParentElement, lineContentElement, textFileElement, $button;
    $currentTarget = $(e.currentTarget);

    if ($currentTarget.hasClass('js-no-comment-btn')) return;

    lineContentElement = this.getLineContent($currentTarget);
    buttonParentElement = this.getButtonParent($currentTarget);

    if (!this.validateButtonParent(buttonParentElement) || !this.validateLineContent(lineContentElement)) return;

    $button = $(COMMENT_BUTTON_CLASS, buttonParentElement);
    buttonParentElement.addClass('is-over')
      .nextUntil(`.${LINE_CONTENT_CLASS}`).addClass('is-over');

    if ($button.length) {
      return;
    }

    textFileElement = this.getTextFileElement($currentTarget);
    buttonParentElement.append(this.buildButton({
      discussionID: lineContentElement.attr('data-discussion-id'),
      lineType: lineContentElement.attr('data-line-type'),

      noteableType: textFileElement.attr('data-noteable-type'),
      noteableID: textFileElement.attr('data-noteable-id'),
      commitID: textFileElement.attr('data-commit-id'),
      noteType: lineContentElement.attr('data-note-type'),

      // LegacyDiffNote
      lineCode: lineContentElement.attr('data-line-code'),

      // DiffNote
      position: lineContentElement.attr('data-position')
    }));
  };

  FilesCommentButton.prototype.hideButton = function(e) {
    var $currentTarget = $(e.currentTarget);
    var buttonParentElement = this.getButtonParent($currentTarget);

    buttonParentElement.removeClass('is-over')
      .nextUntil(`.${LINE_CONTENT_CLASS}`).removeClass('is-over');
  };

  FilesCommentButton.prototype.buildButton = function(buttonAttributes) {
    return $commentButtonTemplate.clone().attr({
      'data-discussion-id': buttonAttributes.discussionID,
      'data-line-type': buttonAttributes.lineType,

      'data-noteable-type': buttonAttributes.noteableType,
      'data-noteable-id': buttonAttributes.noteableID,
      'data-commit-id': buttonAttributes.commitID,
      'data-note-type': buttonAttributes.noteType,

      // LegacyDiffNote
      'data-line-code': buttonAttributes.lineCode,

      // DiffNote
      'data-position': buttonAttributes.position
    });
  };

  FilesCommentButton.prototype.getTextFileElement = function(hoveredElement) {
    return hoveredElement.closest(TEXT_FILE_SELECTOR);
  };

  FilesCommentButton.prototype.getLineContent = function(hoveredElement) {
    if (hoveredElement.hasClass(LINE_CONTENT_CLASS)) {
      return hoveredElement;
    }
    if (!this.isParallelView) {
      return $(hoveredElement).closest(LINE_HOLDER_CLASS).find("." + LINE_CONTENT_CLASS);
    } else {
      return $(hoveredElement).next("." + LINE_CONTENT_CLASS);
    }
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

  FilesCommentButton.prototype.validateLineContent = function(lineContentElement) {
    return lineContentElement.attr('data-note-type') && lineContentElement.attr('data-note-type') !== '';
  };

  return FilesCommentButton;
})();

$.fn.filesCommentButton = function() {
  $commentButtonTemplate = $('<button name="button" type="submit" class="add-diff-note js-add-diff-note-button" title="Add a comment to this line"><i class="fa fa-comment-o"></i></button>');

  if (!(this && (this.parent().data('can-create-note') != null))) {
    return;
  }
  return this.each(function() {
    if (!$.data(this, 'filesCommentButton')) {
      return $.data(this, 'filesCommentButton', new FilesCommentButton($(this)));
    }
  });
};
