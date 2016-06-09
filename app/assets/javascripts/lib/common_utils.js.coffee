((w) ->

  w.gl       or= {}
  w.gl.utils or= {}

  w.gl.utils.isInGroupsPage = ->

    return $('body').data('page').split(':')[0] is 'groups'


  w.gl.utils.isInProjectPage = ->

    return $('body').data('page').split(':')[0] is 'projects'


  w.gl.utils.getProjectSlug = ->

    return if @isInProjectPage() then $('body').data 'project' else null


  w.gl.utils.getGroupSlug = ->

    return if @isInGroupsPage() then $('body').data 'group' else null


) window
