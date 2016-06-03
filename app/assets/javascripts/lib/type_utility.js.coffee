((w) ->

  w.gl ?= {}
  w.gl.utils ?= {}

  w.gl.utils.isObject = (obj) ->
    obj? and (obj.constructor is Object)

) window
