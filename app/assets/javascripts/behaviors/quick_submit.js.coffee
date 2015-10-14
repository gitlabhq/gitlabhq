# Quick Submit behavior
#
# When an input field with the `js-quick-submit` class receives a "Meta+Enter"
# (Mac) or "Ctrl+Enter" (Linux/Windows) key combination, its parent form is
# submitted.
#
#= require extensions/jquery
#
# ### Example Markup
#
#   <form action="/foo">
#     <input type="text" class="js-quick-submit" />
#     <textarea class="js-quick-submit"></textarea>
#   </form>
#
$(document).on 'keydown.quick_submit', '.js-quick-submit', (e) ->
  return if (e.originalEvent && e.originalEvent.repeat) || e.repeat
  return unless e.keyCode == 13 # Enter

  if navigator.userAgent.match(/Macintosh/)
    return unless (e.metaKey && !e.altKey && !e.ctrlKey && !e.shiftKey)
  else
    return unless (e.ctrlKey && !e.altKey && !e.metaKey && !e.shiftKey)

  e.preventDefault()

  $form = $(e.target).closest('form')
  $form.find('input[type=submit], button[type=submit]').disable()
  $form.submit()
