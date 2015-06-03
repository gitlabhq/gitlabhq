# Disable an element and add the 'disabled' Bootstrap class
$.fn.extend disable: ->
  $(@)
    .attr('disabled', 'disabled')
    .addClass('disabled')

# Enable an element and remove the 'disabled' Bootstrap class
$.fn.extend enable: ->
  $(@)
    .removeAttr('disabled')
    .removeClass('disabled')
