#= require jquery.ba-resize
#= require autosize

$ ->
  $fields = $('.js-autosize')

  $fields.on 'autosize:resized', ->
    $field = $(@)
    $field.data('height', $field.outerHeight())

  $fields.on 'resize.autosize', ->
    $field = $(@)

    if $field.data('height') != $field.outerHeight()
      $field.data('height', $field.outerHeight())
      autosize.destroy($field)
      $field.css('max-height', window.outerHeight)

  autosize($fields)
  autosize.update($fields)

  $fields.css('resize', 'vertical')
