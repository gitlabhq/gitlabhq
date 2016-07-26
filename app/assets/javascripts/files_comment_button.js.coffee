class @FilesCommentButton
  COMMENT_BUTTON_CLASS = '.add-diff-note'
  COMMENT_BUTTON_TEMPLATE = _.template '<button name="button" type="submit" class="btn <%- COMMENT_BUTTON_CLASS %> js-add-diff-note-button" title="Add a comment to this line"><i class="fa fa-comment-o"></i></button>'
  LINE_HOLDER_CLASS = '.line_holder'
  LINE_NUMBER_CLASS = 'diff-line-num'
  LINE_CONTENT_CLASS = 'line_content'
  UNFOLDABLE_LINE_CLASS = 'js-unfold'
  EMPTY_CELL_CLASS = 'empty-cell'
  OLD_LINE_CLASS = 'old_line'
  LINE_COLUMN_CLASSES = ".#{LINE_NUMBER_CLASS}, .line_content"
  TEXT_FILE_SELECTOR = '.text-file'
  DEBOUNCE_TIMEOUT_DURATION = 100

  constructor: (@filesContainerElement) ->
    @VIEW_TYPE = $('input#view[type=hidden]').val()

    debounce = _.debounce @render, DEBOUNCE_TIMEOUT_DURATION

    $(@filesContainerElement)
      .off 'mouseover', LINE_COLUMN_CLASSES
      .off 'mouseleave', LINE_COLUMN_CLASSES
      .on 'mouseover', LINE_COLUMN_CLASSES, debounce
      .on 'mouseleave', LINE_COLUMN_CLASSES, @destroy

  render: (e) =>
    $currentTarget = $(e.currentTarget)
    buttonParentElement = @getButtonParent $currentTarget
    return unless @shouldRender e, buttonParentElement

    textFileElement = @getTextFileElement $currentTarget
    lineContentElement = @getLineContent $currentTarget

    buttonParentElement.append @buildButton
      noteableType: textFileElement.attr 'data-noteable-type'
      noteableID: textFileElement.attr 'data-noteable-id'
      commitID: textFileElement.attr 'data-commit-id'
      noteType: lineContentElement.attr 'data-note-type'
      position: lineContentElement.attr 'data-position'
      lineType: lineContentElement.attr 'data-line-type'
      discussionID: lineContentElement.attr 'data-discussion-id'
      lineCode: lineContentElement.attr 'data-line-code'
    return

  destroy: (e) =>
    return if @isMovingToSameType e
    $(COMMENT_BUTTON_CLASS, @getButtonParent $(e.currentTarget)).remove()
    return

  buildButton: (buttonAttributes) ->
    initializedButtonTemplate = COMMENT_BUTTON_TEMPLATE
      COMMENT_BUTTON_CLASS: COMMENT_BUTTON_CLASS.substr 1
    $(initializedButtonTemplate).attr
      'data-noteable-type': buttonAttributes.noteableType
      'data-noteable-id': buttonAttributes.noteableID
      'data-commit-id': buttonAttributes.commitID
      'data-note-type': buttonAttributes.noteType
      'data-line-code': buttonAttributes.lineCode
      'data-position': buttonAttributes.position
      'data-discussion-id': buttonAttributes.discussionID
      'data-line-type': buttonAttributes.lineType

  getTextFileElement: (hoveredElement) ->
    $(hoveredElement.closest TEXT_FILE_SELECTOR)

  getLineContent: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass LINE_CONTENT_CLASS

    if @VIEW_TYPE is 'inline'
      return $(hoveredElement).closest(LINE_HOLDER_CLASS).find ".#{LINE_CONTENT_CLASS}"
    else
      return $(hoveredElement).next ".#{LINE_CONTENT_CLASS}"

  getButtonParent: (hoveredElement) ->
    if @VIEW_TYPE is 'inline'
      return hoveredElement if hoveredElement.hasClass OLD_LINE_CLASS

      hoveredElement.parent().find ".#{OLD_LINE_CLASS}"
    else
      return hoveredElement if hoveredElement.hasClass LINE_NUMBER_CLASS

      $(hoveredElement).prev ".#{LINE_NUMBER_CLASS}"

  isMovingToSameType: (e) ->
    newButtonParent = @getButtonParent $(e.toElement)
    return false unless newButtonParent
    newButtonParent.is @getButtonParent $(e.currentTarget)

  shouldRender: (e, buttonParentElement) ->
    (not buttonParentElement.hasClass(EMPTY_CELL_CLASS) and \
    not buttonParentElement.hasClass(UNFOLDABLE_LINE_CLASS) and \
    $(COMMENT_BUTTON_CLASS, buttonParentElement).length is 0)

$.fn.filesCommentButton = ->
  return unless this and @parent().data('can-create-note')?

  @each ->
    unless $.data this, 'filesCommentButton'
      $.data this, 'filesCommentButton', new FilesCommentButton $(this)
