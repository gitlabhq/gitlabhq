class Shortcuts
  constructor: ->
    if $('#modal-shortcuts').length > 0
      $('#modal-shortcuts').modal('show')
    else
      $.ajax(
        url: '/help/shortcuts',
        dataType: "script"
      )

@Shortcuts = Shortcuts
