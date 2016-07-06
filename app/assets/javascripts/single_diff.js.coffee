class @SingleDiff

  LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>'
  ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>'
  COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. Click to expand it.</div>'

  constructor: (@file) ->
    @content = $('.diff-content', @file)
    @diffForPath = @content.find('[data-diff-for-path]').data 'diff-for-path'
    @setOpenState()

    $('.file-title > a', @file).on 'click', @toggleDiff
    @enableToggleOnContent()

  setOpenState: ->
    if @diffForPath
      @isOpen = false
    else
      @isOpen = true
      @contentHTML = @content.html()
    return

  enableToggleOnContent: ->
    @content.find('.nothing-here-block.diff-collapsed').on 'click', @toggleDiff

  toggleDiff: (e) =>
    e.preventDefault()
    @isOpen = !@isOpen
    if not @isOpen and not @hasError
      @content.html COLLAPSED_HTML
      @enableToggleOnContent
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
