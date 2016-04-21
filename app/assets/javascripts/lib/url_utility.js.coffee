((w) ->

  w.gl ?= {}
  w.gl.utils ?= {}

  # Returns an array containing the value(s) of the
  # of the key passed as an argument
  w.gl.utils.getParameterValues = (sParam) ->
    sPageURL = decodeURIComponent(window.location.search.substring(1))
    sURLVariables = sPageURL.split('&')
    sParameterName = undefined
    values = []
    i = 0
    while i < sURLVariables.length
      sParameterName = sURLVariables[i].split('=')
      if sParameterName[0] is sParam
        values.push(sParameterName[1])
      i++
    values

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

  # removes parameter query string from url. returns the modified url
  w.gl.utils.removeParamQueryString = (url, param) ->
    url = decodeURIComponent(url)
    urlVariables = url.split('&')
    (
      variables for variables in urlVariables when variables.indexOf(param) is -1
    ).join('&')

) window
