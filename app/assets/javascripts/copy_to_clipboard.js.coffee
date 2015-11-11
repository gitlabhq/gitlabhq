#= require clipboard

$ ->
  clipboard = new Clipboard '.js-clipboard-trigger',
    text: (trigger) ->
      $target = $(trigger.nextElementSibling || trigger.previousElementSibling)
      $target.data('clipboard-text') || $target.text().trim()

  clipboard.on 'success', (e) ->
    $(e.trigger).
      tooltip(trigger: 'manual', placement: 'auto bottom', title: 'Copied!').
      tooltip('show')

    # Clear the selection and blur the trigger so it loses its border
    e.clearSelection()
    $(e.trigger).blur()

    # Manually hide the tooltip after 1 second
    setTimeout(->
      $(e.trigger).tooltip('hide')
    , 1000)
