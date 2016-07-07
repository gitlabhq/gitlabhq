class @FilesCommentButton
  constructor: (@filesContainerElement) ->
    return unless @filesContainerElement
    return if _.isUndefined @filesContainerElement.data 'can-create-note'

    @COMMENT_BUTTON_CLASS = '.add-diff-note'
    @COMMENT_BUTTON_TEMPLATE = _.template '<button name="button" type="submit" class="btn <%- COMMENT_BUTTON_CLASS %> js-add-diff-note-button" title="Add a comment to this line"><i class="fa fa-comment-o"></i></button>'

    @LINE_NUMBER_CLASS = 'diff-line-num'
    @LINE_CONTENT_CLASS = 'line_content'
    @UNFOLDABLE_LINE_CLASS = 'js-unfold'
    @EMPTY_CELL_CLASS = 'empty-cell'
    @OLD_LINE_CLASS = 'old_line'
    @LINE_COLUMN_CLASSES = ".#{@LINE_NUMBER_CLASS}, .line_content"
    @TEXT_FILE_SELECTOR = '.text-file'

    @DEBOUNCE_TIMEOUT_DURATION = 150

    @VIEW_TYPE = $('input#view[type=hidden]').val()

    $(document)
      .on 'mouseover', @LINE_COLUMN_CLASSES, @debounceRender
      .on 'mouseleave', @LINE_COLUMN_CLASSES, @destroy

  debounceRender: (e) =>
    clearTimeout @debounceTimeout if @debounceTimeout
    @debounceTimeout = setTimeout =>
      @render e
    , @DEBOUNCE_TIMEOUT_DURATION
    return

  render: (e) ->
    currentTarget = $(e.currentTarget)
    textFileElement = @getTextFileElement(currentTarget)
    lineContentElement = @getLineContent(currentTarget)
    buttonParentElement = @getButtonParent(currentTarget)

    return unless @shouldRender e, buttonParentElement

    buttonParentElement.append @buildButton
      noteable_type: textFileElement.attr 'data-noteable-type'
      noteable_id: textFileElement.attr 'data-noteable-id'
      commit_id: textFileElement.attr 'data-commit-id'
      note_type: lineContentElement.attr 'data-note-type'
      position: lineContentElement.attr 'data-position'
      line_type: lineContentElement.attr 'data-line-type'
      discussion_id: lineContentElement.attr 'data-discussion-id'
      line_code: lineContentElement.attr 'data-line-code'
    return

  destroy: (e) =>
    return if @isMovingToSameType e
    $(@COMMENT_BUTTON_CLASS, @getButtonParent $(e.currentTarget)).remove()
    return

  buildButton: (buttonAttributes) ->
    initializedButtonTemplate = @COMMENT_BUTTON_TEMPLATE
      COMMENT_BUTTON_CLASS: @COMMENT_BUTTON_CLASS.substr 1
    $(initializedButtonTemplate).attr
      'data-noteable-type': buttonAttributes.noteable_type
      'data-noteable-id': buttonAttributes.noteable_id
      'data-commit-id': buttonAttributes.commit_id
      'data-note-type': buttonAttributes.note_type
      'data-line-code': buttonAttributes.line_code
      'data-position': buttonAttributes.position
      'data-discussion-id': buttonAttributes.discussion_id
      'data-line-type': buttonAttributes.line_type

  getTextFileElement: (hoveredElement) ->
    $(hoveredElement.closest(@TEXT_FILE_SELECTOR))

  getLineContent: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass @LINE_CONTENT_CLASS

    $(hoveredElement).next ".#{@LINE_CONTENT_CLASS}"

  getButtonParent: (hoveredElement) ->
    if @VIEW_TYPE is 'inline'
      return hoveredElement if hoveredElement.hasClass @OLD_LINE_CLASS

      $(hoveredElement).parent().find ".#{@OLD_LINE_CLASS}"
    else
      return hoveredElement if hoveredElement.hasClass @LINE_NUMBER_CLASS

      $(hoveredElement).prev ".#{@LINE_NUMBER_CLASS}"

  isMovingToSameType: (e) ->
    newButtonParent = @getButtonParent($(e.toElement))
    return false unless newButtonParent
    (newButtonParent).is @getButtonParent($(e.currentTarget))

  shouldRender: (e, buttonParentElement) ->
    (!buttonParentElement.hasClass(@EMPTY_CELL_CLASS) and \
    !buttonParentElement.hasClass(@UNFOLDABLE_LINE_CLASS) and \
    $(@COMMENT_BUTTON_CLASS, buttonParentElement).length is 0)
