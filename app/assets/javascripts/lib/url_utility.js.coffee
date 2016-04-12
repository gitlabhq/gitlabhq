((w) ->

  w.gl ?= {}
  w.gl.utils ?= {}

  w.gl.utils.getUrlParameter = (sParam) ->
    sPageURL = decodeURIComponent(window.location.search.substring(1))
    sURLVariables = sPageURL.split('&')
    sParameterName = undefined
    i = 0
    while i < sURLVariables.length
      sParameterName = sURLVariables[i].split('=')
      if sParameterName[0] is sParam
        return if sParameterName[1] is undefined then true else sParameterName[1]
      i++

  # #
  #  @param {Object} params - url keys and value to merge
  #  @param {String} url
  # #
  w.gl.utils.mergeUrlParams = (params, url) ->
    newUrl = decodeURIComponent(url)
    for paramName, paramValue of params
      pattern = new RegExp "\\b(#{paramName}=).*?(&|$)"
      if url.search(pattern) >= 0
        newUrl = newUrl.replace pattern, "$1#{paramValue}$2"
      else
        newUrl = "#{newUrl}#{(if newUrl.indexOf('?') > 0 then '&' else '?')}#{paramName}=#{paramValue}"
    newUrl

) window
