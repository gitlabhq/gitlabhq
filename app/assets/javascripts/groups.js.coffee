class @GroupMembers
  constructor: ->
    $('li.group_member').bind 'ajax:success', ->
      $(this).fadeOut()
