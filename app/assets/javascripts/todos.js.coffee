class @Todos
  constructor: (@name) ->
    @clearListeners()
    @initBtnListeners()

  clearListeners: ->
    $('.done-todo').off('click')

  initBtnListeners: ->
    $('.done-todo').on('click', @doneClicked)

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
        @clearDone $this.closest('li'), data

  clearDone: ($row, data) ->
    $ul = $row.closest('ul')
    $row.remove()

    $('.todos-pending .badge, .todos-pending-count').text data.count
    $('.todos-done .badge').text data.done_count

    if not $ul.find('li').length
      $ul.parents('.panel').remove()
