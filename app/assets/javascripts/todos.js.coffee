class @Todos
  constructor: (@name) ->
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

  goToTodoUrl: (e)->
    todoLink = $(this).data('url')
    return unless todoLink

    if e.metaKey
      e.preventDefault()
      window.open(todoLink,'_blank')
    else
      Turbolinks.visit(todoLink)
