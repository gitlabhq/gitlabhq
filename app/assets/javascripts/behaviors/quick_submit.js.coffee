# Quick Submit behavior
#
# When a child field of a form with a `js-quick-submit` class receives a
# "Meta+Enter" (Mac) or "Ctrl+Enter" (Linux/Windows) key combination, the form
# is submitted.
#
#= require extensions/jquery
#
# ### Example Markup
#
#   <form action="/foo" class="js-quick-submit">
#     <input type="text" />
#     <textarea></textarea>
#     <input type="submit" value="Submit" />
#   </form>
#
isMac = ->
  navigator.userAgent.match(/Macintosh/)

keyCodeIs = (e, keyCode) ->
  return false if (e.originalEvent && e.originalEvent.repeat) || e.repeat
  return e.keyCode == keyCode

$(document).on 'keydown.quick_submit', '.js-quick-submit', (e) ->
  return unless keyCodeIs(e, 13) # Enter

  return unless (e.metaKey && !e.altKey && !e.ctrlKey && !e.shiftKey) || (e.ctrlKey && !e.altKey && !e.metaKey && !e.shiftKey)

  e.preventDefault()

  $form = $(e.target).closest('form')
  $form.find('input[type=submit], button[type=submit]').disable()
  $form.submit()

# If the user tabs to a submit button on a `js-quick-submit` form, display a
# tooltip to let them know they could've used the hotkey
$(document).on 'keyup.quick_submit', '.js-quick-submit input[type=submit], .js-quick-submit button[type=submit]', (e) ->
  return unless keyCodeIs(e, 9) # Tab

  if isMac()
    title = "You can also press &#8984;-Enter"
  else
    title = "You can also press Ctrl-Enter"

  $this = $(@)
  $this.tooltip(
    container: 'body'
    html: 'true'
    placement: 'auto top'
    title: title
    trigger: 'manual'
  ).tooltip('show').one('blur', -> $this.tooltip('hide'))
