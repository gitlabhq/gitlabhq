$ ->
  $('.js-branch-dev-push').on 'click', (e) ->
    e.preventDefault()

    id = $(this).data('value')
    checked = $(this).is(':not(.is-active)')
    url = $(this).data('url')
    $.ajax
      type: 'PUT'
      url: url
      dataType: 'json'
      data:
        id: id
        developers_can_push: checked
      success: =>
        $(this).toggleClass 'is-active'
      error: ->
        new Flash('Failed to update branch!', 'alert')
