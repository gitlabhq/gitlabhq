$.fn.changeElementType = (newType) ->
  attrs = {}
  $.each @[0].attributes, (i, attr) ->
    attrs[attr.nodeName] = attr.nodeValue
    return
  @replaceWith ->
    $('<' + newType + '/>', attrs).append $(this).contents()
  return