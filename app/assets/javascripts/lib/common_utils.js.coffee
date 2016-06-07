((w) ->

  w.gl       or= {}
  w.gl.utils or= {}

  w.gl.utils.getProjectSlug = ->

    $body = $ 'body'
    isInProjectPage = $body.data('page').split(':')[0] is 'projects'

    return if isInProjectPage then $body.data 'project' else null

) window
