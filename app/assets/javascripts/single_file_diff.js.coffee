class @SingleFileDiff

  WRAPPER = '<div class="diff-content diff-wrap-lines"></div>'
  LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>'
  ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>'
  COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. Click to expand it.</div>'

  constructor: (@file) ->
    @content = $('.diff-content', @file)
    @diffForPath = @content.find('[data-diff-for-path]').data 'diff-for-path'
    @isOpen = !@diffForPath

    if @diffForPath
      @collapsedContent = @content
      @loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide()
      @content = null
      @collapsedContent.after(@loadingContent)
    else
      @collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide()
      @content.after(@collapsedContent)

    @collapsedContent.on 'click', @toggleDiff

    $('.file-title > a', @file).on 'click', @toggleDiff

  toggleDiff: (e) =>
    @isOpen = !@isOpen
    if not @isOpen and not @hasError
      @content.hide()
      @collapsedContent.show()
    else if @content
      @collapsedContent.hide()
      @content.show()
    else
      @getContentHTML()

  getContentHTML: ->
    @collapsedContent.hide()
    @loadingContent.show()
    $.get @diffForPath, (data) =>
      @loadingContent.hide()
      if data.html
        @content = $(data.html)
        @content.syntaxHighlight()
      else
        @hasError = true
        @content = $(ERROR_HTML)
      @collapsedContent.after(@content)
    return

$.fn.singleFileDiff = ->
  return @each ->
    if not $.data this, 'singleFileDiff'
      $.data this, 'singleFileDiff', new SingleFileDiff this
