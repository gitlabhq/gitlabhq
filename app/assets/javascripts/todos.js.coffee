class @Todos
  constructor: (opts = {}) ->
    {
      @el = $('.js-todos-options')
    } = opts

    @perPage = @el.data('perPage')

    @clearListeners()
    @initBtnListeners()

  clearListeners: ->
    $('.done-todo').off('click')
    $('.js-todos-mark-all').off('click')
    $('.todo').off('click')

  initBtnListeners: ->
    $('.done-todo').on('click', @doneClicked)
    $('.js-todos-mark-all').on('click', @allDoneClicked)
    $('.todo').on('click', @goToTodoUrl)

  doneClicked: (e) =>
    e.preventDefault()
    e.stopImmediatePropagation()

    $this = $(e.currentTarget)
    $this.disable()

    $.ajax
      type: 'POST'
      url: $this.attr('href')
      dataType: 'json'
      data: '_method': 'delete'
      success: (data) =>
        @redirectIfNeeded data.count
        @clearDone $this.closest('li')
        @updateBadges data

  allDoneClicked: (e) =>
    e.preventDefault()
    e.stopImmediatePropagation()

    $this = $(e.currentTarget)
    $this.disable()

    $.ajax
      type: 'POST'
      url: $this.attr('href')
      dataType: 'json'
      data: '_method': 'delete'
      success: (data) =>
        $this.remove()
        $('.js-todos-list').remove()
        @updateBadges data

  clearDone: ($row) ->
    $ul = $row.closest('ul')
    $row.remove()

    if not $ul.find('li').length
      $ul.parents('.panel').remove()

  updateBadges: (data) ->
    $('.todos-pending .badge, .todos-pending-count').text data.count
    $('.todos-done .badge').text data.done_count

  getTotalPages: ->
    @el.data('totalPages')

  getCurrentPage: ->
    @el.data('currentPage')

  getTodosPerPage: ->
    @el.data('perPage')

  redirectIfNeeded: (total) ->
    currPages = @getTotalPages()
    currPage = @getCurrentPage()

    # Refresh if no remaining Todos
    if not total
      location.reload()
      return

    # Do nothing if no pagination
    return if not currPages

    newPages = Math.ceil(total / @getTodosPerPage())
    url = location.href # Includes query strings

    # If new total of pages is different than we have now
    if newPages isnt currPages
      # Redirect to previous page if there's one available
      if currPages > 1 and currPage is currPages
        pageParams =
          page: currPages - 1
        url = gl.utils.mergeUrlParams(pageParams, url)

      Turbolinks.visit(url)

  goToTodoUrl: (e)->
    todoLink = $(this).data('url')
    return unless todoLink

    if e.metaKey
      e.preventDefault()
      window.open(todoLink,'_blank')
    else
      Turbolinks.visit(todoLink)
