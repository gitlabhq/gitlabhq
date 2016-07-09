((w) ->

  w.gl       or= {}
  w.gl.utils or= {}

  w.gl.utils.isInGroupsPage = ->

    return gl.utils.getPagePath() is 'groups'


  w.gl.utils.isInProjectPage = ->

    return gl.utils.getPagePath() is 'projects'


  w.gl.utils.getProjectSlug = ->

    return if @isInProjectPage() then $('body').data 'project' else null


  w.gl.utils.getGroupSlug = ->

    return if @isInGroupsPage() then $('body').data 'group' else null



  gl.utils.updateTooltipTitle = ($tooltipEl, newTitle) ->

    $tooltipEl
      .tooltip 'destroy'
      .attr    'title', newTitle
      .tooltip 'fixTitle'


  gl.utils.preventDisabledButtons = ->

    $('.btn').click (e) ->
      if $(this).hasClass 'disabled'
        e.preventDefault()
        e.stopImmediatePropagation()
        return false
  
  gl.utils.capitalize = (str) ->
    return str[0].toUpperCase() + str.slice(1);

  gl.utils.getPagePath = ->
    return $('body').data('page').split(':')[0]


  jQuery.timefor = (time, suffix, expiredLabel) ->

    return '' unless time

    suffix       or= 'remaining'
    expiredLabel or= 'Past due'

    jQuery.timeago.settings.allowFuture = yes

    { suffixFromNow } = jQuery.timeago.settings.strings
    jQuery.timeago.settings.strings.suffixFromNow = suffix

    timefor = $.timeago time

    if timefor.indexOf('ago') > -1
      timefor = expiredLabel

    jQuery.timeago.settings.strings.suffixFromNow = suffixFromNow

    return timefor

) window
