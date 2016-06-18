class @FilesCommentButton
  constructor: (@filesContainerElement) ->
    return if not @filesContainerElement and not @filesContainerElement.data 'can-create-note'

    @COMMENT_BUTTON_CLASS = '.add-diff-note'
    @COMMENT_BUTTON_TEMPLATE = _.template("<button name='button' type='submit' class='btn <%- COMMENT_BUTTON_CLASS %> js-add-diff-note-button' title='Add a comment to this line'><i class='fa fa-comment-o'></i></button>")

    @LINE_HOLDER_CLASS = '.line_holder'
    @LINE_NUMBER_CLASS = 'diff-line-num'
    @LINE_CONTENT_CLASS = 'line_content'
    @LINE_COLUMN_CLASSES = ".#{@LINE_NUMBER_CLASS}, .line_content"

    @DEBOUNCE_TIMEOUT_DURATION = 150

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
    lineHolderElement = @getLineHolder($(e.currentTarget))
    lineContentElement = @getLineContent($(e.currentTarget))
    lineNumElement = @getLineNum($(e.currentTarget))
    buttonParentElement = lineNumElement

    return if not @shouldRender e, buttonParentElement

    buttonParentElement.append @buildButton
      id:
        noteable: lineHolderElement.attr 'data-noteable-id'
        commit: lineHolderElement.attr 'data-commit-id'
        discussion: lineContentElement.attr('data-discussion-id') || lineHolderElement.attr('data-discussion-id')
      type:
        noteable: lineHolderElement.attr 'data-noteable-type'
        note: lineHolderElement.attr 'data-note-type'
        line: lineContentElement.attr 'data-line-type'
      code:
        line: lineContentElement.attr('data-line-code') || lineHolderElement.attr('id')
    return

  destroy: (e) =>
    return if @isMovingToSameType e
    $(@COMMENT_BUTTON_CLASS, @getLineNum $(e.currentTarget)).remove()
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

  getLineHolder: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass @LINE_HOLDER_CLASS
    $(hoveredElement.parent())

  getLineNum: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass @LINE_NUMBER_CLASS

    $(hoveredElement).prev('.' + @LINE_NUMBER_CLASS)

  getLineContent: (hoveredElement) ->
    return hoveredElement if hoveredElement.hasClass @LINE_CONTENT_CLASS

    $(hoveredElement).next('.' + @LINE_CONTENT_CLASS)

  isMovingToSameType: (e) ->
    newLineNum = @getLineNum($(e.toElement))
    return false unless newLineNum
    (newLineNum).is @getLineNum($(e.currentTarget))

  shouldRender: (e, buttonParentElement) ->
    (!buttonParentElement.hasClass('empty-cell') and $(@COMMENT_BUTTON_CLASS, buttonParentElement).length is 0)
