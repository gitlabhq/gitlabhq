class @User
  constructor: ->
    $('.profile-groups-avatars').tooltip("placement": "top")
    ProjectsList.init()

    $('.hide-project-limit-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_project_limit_message', 'false', { path: path })
      $(@).parents('.project-limit-message').remove()
      e.preventDefault()
