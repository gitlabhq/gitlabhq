$.fn.showAndHide = ->
  $(@).show().
    delay(3000).
    fadeOut()

$.fn.enableButton = ->
  $(@).removeAttr('disabled').
    removeClass('disabled')

