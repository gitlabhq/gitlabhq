class @FilesCommentButton
  constructor: (@filesContainerElement) ->
    return if not @filesContainerElement
    return if not @filesContainerElement.data 'can-create-note'

    @COMMENT_BUTTON_CLASS = '.add-diff-note'
    @COMMENT_BUTTON_TEMPLATE = _.template("<button name='button' type='submit' class='btn <%- COMMENT_BUTTON_CLASS %> js-add-diff-note-button' title='Add a comment to this line'><i class='fa fa-comment-o'></i></button>")

    @LINE_HOLDER_CLASS = '.line_holder'
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
    lineHolderElement = @getLineHolder(currentTarget)
    lineContentElement = @getLineContent(currentTarget)
    buttonParentElement = @getButtonParent(currentTarget)

    return if not @shouldRender e, buttonParentElement

    buttonParentElement.append @buildButton
      id:
        noteable: textFileElement.attr 'data-noteable-id'
        commit: textFileElement.attr 'data-commit-id'
        discussion: lineContentElement.attr('data-discussion-id') or lineHolderElement.attr('data-discussion-id')
      type:
        noteable: textFileElement.attr 'data-noteable-type'
        note: textFileElement.attr 'data-note-type'
        line: lineContentElement.attr 'data-line-type'
      code:
        line: lineContentElement.attr('data-line-code') or lineHolderElement.attr('id')
    return

  destroy: (e) =>
    return if @isMovingToSameType e
    $(@COMMENT_BUTTON_CLASS, @getButtonParent $(e.currentTarget)).remove()
    return

  buildButton: (buttonAttributes) ->
    $(@COMMENT_BUTTON_TEMPLATE COMMENT_BUTTON_CLASS: @COMMENT_BUTTON_CLASS.substr 1).attr
      'data-noteable-id': buttonAttributes.id.noteable
      'data-commit-id': buttonAttributes.id.commit
      'data-discussion-id': buttonAttributes.id.discussion
      'data-noteable-type': buttonAttributes.type.noteable
      'data-line-type': buttonAttributes.type.line
      'data-note-type': buttonAttributes.type.note
      'data-line-code': buttonAttributes.code.line

  getTextFileElement: (hoveredElement) ->
    $(hoveredElement.closest(@TEXT_FILE_SELECTOR))

  getLineHolder: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass @LINE_HOLDER_CLASS
    $(hoveredElement.parent())

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
