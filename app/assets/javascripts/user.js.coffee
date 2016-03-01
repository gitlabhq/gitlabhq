class @User
  constructor: (@opts) ->
    $('.profile-groups-avatars').tooltip("placement": "top")
    new ProjectsList()

    @initTabs()

    $('.hide-project-limit-message').on 'click', (e) ->
      path = '/'
      $.cookie('hide_project_limit_message', 'false', { path: path })
      $(@).parents('.project-limit-message').remove()
      e.preventDefault()

  initTabs: ->
    new UserTabs(@opts)
