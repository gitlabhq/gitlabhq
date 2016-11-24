/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, max-len, one-var, one-var-declaration-per-line, quotes, prefer-template, newline-per-chained-call, comma-dangle, new-cap, no-else-return, padded-blocks, consistent-return, no-undef, max-len */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.FilesCommentButton = (function() {
    var COMMENT_BUTTON_CLASS, COMMENT_BUTTON_TEMPLATE, DEBOUNCE_TIMEOUT_DURATION, EMPTY_CELL_CLASS, LINE_COLUMN_CLASSES, LINE_CONTENT_CLASS, LINE_HOLDER_CLASS, LINE_NUMBER_CLASS, OLD_LINE_CLASS, TEXT_FILE_SELECTOR, UNFOLDABLE_LINE_CLASS;

    COMMENT_BUTTON_CLASS = '.add-diff-note';

    COMMENT_BUTTON_TEMPLATE = _.template('<button name="button" type="submit" class="btn <%- COMMENT_BUTTON_CLASS %> js-add-diff-note-button" title="Add a comment to this line"><i class="fa fa-comment-o"></i></button>');

    LINE_HOLDER_CLASS = '.line_holder';

    LINE_NUMBER_CLASS = 'diff-line-num';

    LINE_CONTENT_CLASS = 'line_content';

    UNFOLDABLE_LINE_CLASS = 'js-unfold';

    EMPTY_CELL_CLASS = 'empty-cell';

    OLD_LINE_CLASS = 'old_line';

    LINE_COLUMN_CLASSES = "." + LINE_NUMBER_CLASS + ", .line_content";

    TEXT_FILE_SELECTOR = '.text-file';

    DEBOUNCE_TIMEOUT_DURATION = 100;

    function FilesCommentButton(filesContainerElement) {
      var debounce;
      this.filesContainerElement = filesContainerElement;
      this.destroy = bind(this.destroy, this);
      this.render = bind(this.render, this);
      this.VIEW_TYPE = $('input#view[type=hidden]').val();
      debounce = _.debounce(this.render, DEBOUNCE_TIMEOUT_DURATION);
      $(this.filesContainerElement).off('mouseover', LINE_COLUMN_CLASSES).off('mouseleave', LINE_COLUMN_CLASSES).on('mouseover', LINE_COLUMN_CLASSES, debounce).on('mouseleave', LINE_COLUMN_CLASSES, this.destroy);
    }

    FilesCommentButton.prototype.render = function(e) {
      var $currentTarget, buttonParentElement, lineContentElement, textFileElement;
      $currentTarget = $(e.currentTarget);

      buttonParentElement = this.getButtonParent($currentTarget);
      if (!this.validateButtonParent(buttonParentElement)) return;
      lineContentElement = this.getLineContent($currentTarget);
      if (!this.validateLineContent(lineContentElement)) return;

      textFileElement = this.getTextFileElement($currentTarget);
      buttonParentElement.append(this.buildButton({
        noteableType: textFileElement.attr('data-noteable-type'),
        noteableID: textFileElement.attr('data-noteable-id'),
        commitID: textFileElement.attr('data-commit-id'),
        noteType: lineContentElement.attr('data-note-type'),
        position: lineContentElement.attr('data-position'),
        lineType: lineContentElement.attr('data-line-type'),
        discussionID: lineContentElement.attr('data-discussion-id'),
        lineCode: lineContentElement.attr('data-line-code')
      }));
    };

    FilesCommentButton.prototype.destroy = function(e) {
      if (this.isMovingToSameType(e)) {
        return;
      }
      $(COMMENT_BUTTON_CLASS, this.getButtonParent($(e.currentTarget))).remove();
    };

    FilesCommentButton.prototype.buildButton = function(buttonAttributes) {
      var initializedButtonTemplate;
      initializedButtonTemplate = COMMENT_BUTTON_TEMPLATE({
        COMMENT_BUTTON_CLASS: COMMENT_BUTTON_CLASS.substr(1)
      });
      return $(initializedButtonTemplate).attr({
        'data-noteable-type': buttonAttributes.noteableType,
        'data-noteable-id': buttonAttributes.noteableID,
        'data-commit-id': buttonAttributes.commitID,
        'data-note-type': buttonAttributes.noteType,
        'data-line-code': buttonAttributes.lineCode,
        'data-position': buttonAttributes.position,
        'data-discussion-id': buttonAttributes.discussionID,
        'data-line-type': buttonAttributes.lineType
      });
    };

    FilesCommentButton.prototype.getTextFileElement = function(hoveredElement) {
      return $(hoveredElement.closest(TEXT_FILE_SELECTOR));
    };

    FilesCommentButton.prototype.getLineContent = function(hoveredElement) {
      if (hoveredElement.hasClass(LINE_CONTENT_CLASS)) {
        return hoveredElement;
      }
      if (this.VIEW_TYPE === 'inline') {
        return $(hoveredElement).closest(LINE_HOLDER_CLASS).find("." + LINE_CONTENT_CLASS);
      } else {
        return $(hoveredElement).next("." + LINE_CONTENT_CLASS);
      }
    };

    FilesCommentButton.prototype.getButtonParent = function(hoveredElement) {
      if (this.VIEW_TYPE === 'inline') {
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

    FilesCommentButton.prototype.isMovingToSameType = function(e) {
      var newButtonParent;
      newButtonParent = this.getButtonParent($(e.toElement));
      if (!newButtonParent) {
        return false;
      }
      return newButtonParent.is(this.getButtonParent($(e.currentTarget)));
    };

    FilesCommentButton.prototype.validateButtonParent = function(buttonParentElement) {
      return !buttonParentElement.hasClass(EMPTY_CELL_CLASS) && !buttonParentElement.hasClass(UNFOLDABLE_LINE_CLASS) && $(COMMENT_BUTTON_CLASS, buttonParentElement).length === 0;
    };

    FilesCommentButton.prototype.validateLineContent = function(lineContentElement) {
      return lineContentElement.attr('data-discussion-id') && lineContentElement.attr('data-discussion-id') !== '';
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

}).call(this);
