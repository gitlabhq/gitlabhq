((w) ->

  w.gl       or= {}
  w.gl.utils or= {}

  w.gl.utils.isInProjectPage = ->

    return $('body').data('page').split(':')[0] is 'projects'


) window
