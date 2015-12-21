#= require clipboard

genericSuccess = (e) ->
  showTooltip(e.trigger, 'Copied!')

  # Clear the selection and blur the trigger so it loses its border
  e.clearSelection()
  $(e.trigger).blur()

# Safari doesn't support `execCommand`, so instead we inform the user to
# copy manually.
#
# See http://clipboardjs.com/#browser-support
genericError = (e) ->
  if /Mac/i.test(navigator.userAgent)
    key = '&#8984;' # Command
  else
    key = 'Ctrl'

  showTooltip(e.trigger, "Press #{key}-C to copy")

showTooltip = (target, title) ->
  $(target).
    tooltip(
      container: 'body'
      html: 'true'
      placement: 'auto bottom'
      title: title
      trigger: 'manual'
    ).
    tooltip('show').
    one('mouseleave', -> $(this).tooltip('hide'))

$ ->
  clipboard = new Clipboard '[data-clipboard-target], [data-clipboard-text]'
  clipboard.on 'success', genericSuccess
  clipboard.on 'error',   genericError
