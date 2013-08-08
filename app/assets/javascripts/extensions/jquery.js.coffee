$.fn.showAndHide = ->
  $(@).show().
    delay(3000).
    fadeOut()

$.fn.enableButton = ->
  $(@).removeAttr('disabled').
    removeClass('disabled')

$.fn.disableButton = ->
  $(@).attr('disabled', 'disabled').
    addClass('disabled')

