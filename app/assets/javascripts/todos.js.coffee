class @Todos
  _this = null;
  constructor: (@name) ->
    _this = @
    @initBtnListeners()
    
  initBtnListeners: ->
    $('.done-todo').on('click', @doneClicked)
    
  doneClicked: (e) ->
    $this = $(this)
    doneURL = $this.attr('href')
    e.preventDefault()
    e.stopImmediatePropagation()
    $spinner = $('<i></i>').addClass('fa fa-spinner fa-spin')
    $this.addClass("disabled")
    $this.append($spinner)
    $.ajax
      type: 'POST'
      url: doneURL
      dataType: 'json'
      data: '_method': 'delete'
      error: (data, textStatus, jqXHR) ->
        new Flash('Unable to update your todos.', 'alert')
        _this.clearDone($this.closest('li'))
        return

      success: (data, textStatus, jqXHR) ->
        _this.clearDone($this.closest('li'))
        return

  clearDone: ($row) ->
    $ul = $row.closest('ul')
    $row.remove()
    if not $ul.find('li').length
      Turbolinks.visit(location.href)
    else
      $pendingBadge = $('.todos-pending .badge')
      $pendingBadge.text parseInt($pendingBadge.text()) - 1

      $doneBadge = $('.todos-done .badge')
      $doneBadge.text parseInt($doneBadge.text()) + 1

      $mainTodosPendingBadge = $('.todos-pending-count')
      $mainTodosPendingBadge.text parseInt($mainTodosPendingBadge.text()) - 1
    return
    