class @SingleDiff

  LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>'
  ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>'

  constructor: (@file) ->
    @content = $('.diff-content', @file)
    @diffForPath = @content.data 'diff-for-path'
    @setOpenState()

    $('.file-title > a', @file).on 'click', @toggleDiff

  setOpenState: ->
    if @diffForPath
      @isOpen = false
    else
      @isOpen = true
      @contentHTML = @content.html()
    return

  toggleDiff: (e) =>
    e.preventDefault()
    @isOpen = !@isOpen
    if not @isOpen and not @hasError
      @content.empty()
      return
    if @contentHTML
      @setContentHTML()
    else
      @getContentHTML()
    return

  getContentHTML: ->
    @content.html(LOADING_HTML).addClass 'loading'
    $.get @diffForPath, (data) =>
      if data.html
        @setContentHTML data.html
      else
        @hasError = true
        @content.html ERROR_HTML
      @content.removeClass 'loading'
    return

  setContentHTML: (contentHTML) ->
    @contentHTML = contentHTML if contentHTML
    @content.html @contentHTML
    @content.syntaxHighlight()

$.fn.singleDiff = ->
  return @each ->
    if not $.data this, 'singleDiff'
      $.data this, 'singleDiff', new SingleDiff this
