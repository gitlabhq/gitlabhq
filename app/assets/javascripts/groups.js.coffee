class GroupMembers
  constructor: ->
    $('li.users_group').bind 'ajax:success', ->
      $(this).fadeOut()

@GroupMembers = GroupMembers
