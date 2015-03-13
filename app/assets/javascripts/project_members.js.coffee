class @ProjectMembers
  constructor: ->
    $('li.project_member').bind 'ajax:success', ->
      $(this).fadeOut()
