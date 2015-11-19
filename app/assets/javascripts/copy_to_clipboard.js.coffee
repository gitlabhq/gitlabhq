#= require clipboard

$ ->
  clipboard = new Clipboard '.js-clipboard-trigger',
    text: (trigger) ->
      $target = $(trigger.nextElementSibling || trigger.previousElementSibling)
      $target.data('clipboard-text') || $target.text().trim()

  clipboard.on 'success', (e) ->
    $(e.trigger).
      tooltip(trigger: 'manual', placement: 'auto bottom', title: 'Copied!').
      tooltip('show').
      one('mouseleave', -> $(this).tooltip('hide'))

    # Clear the selection and blur the trigger so it loses its border
    e.clearSelection()
    $(e.trigger).blur()

  # Safari doesn't support `execCommand`, so instead we inform the user to
  # copy manually.
  #
  # See http://clipboardjs.com/#browser-support
  clipboard.on 'error', (e) ->
    if /Mac/i.test(navigator.userAgent)
      title = "Press &#8984;-C to copy"
    else
      title = "Press Ctrl-C to copy"

    $(e.trigger).
      tooltip(trigger: 'manual', placement: 'auto bottom', html: true, title: title).
      tooltip('show').
      one('mouseleave', -> $(this).tooltip('hide'))
