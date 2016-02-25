class @Todos
  constructor: ->
    @service = new TodosService()
    new Vue(
      el: '#todos'
      data:{}   
      methods: 
        doneClicked: (e) ->
          e.preventDefault()
          e.stopImmediatePropagation()
          console.log('done clicked');
    )

class @TodosService
  constructor: ->
    console.log('todos service')

  deleteTodo: () ->
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
        new Flash(data.notice, 'success')
        _this.clearDone($this.closest('li'))
        return

  getTodos: () ->
    $.getJSON '/dashboard/todos', (data) ->
    console.log 'data', data
    return