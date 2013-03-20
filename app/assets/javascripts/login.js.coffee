window.loginPage = (initial) ->
  links = $('a.login-toggle')

  # Focus to first form field
  focus = (form) ->
    form.find('input[type=text], input[type=email]').filter(':visible:first').focus();

  # Utility
  form_from = (link) ->
    $(document.getElementById link.data 'form')

  # Show single login element
  show = (focused) ->
    links.each (i, element) ->
      link = $(element)
      form = form_from link
      # Hide form when link was not clicked and form is visible
      if element != focused && form.is ':visible'
        # note: use function generator to cache variable 'link'
        form.slideUp 'slow', ((e) -> -> e.slideDown 'fast') link

      # Show form when link is clicked and form is hidden
      else if element == focused && !form.is ':visible'
        # note: use function generator to cache variable 'form'
        link.slideUp 'fast', ((e) -> -> e.slideDown 'slow', -> focus e) form
      return

  # If there is only single link...
  if links.length == 1
    # ... replace show function
    show = (focused) ->
      (form_from $(focused)).slideToggle()
    # ... show link
    link = links.first().show()
    # ... add br in form for small space between link and input
    form = (form_from link).prepend('<br/>')

  # Initialize login page elements
  links.each (i, element) ->
    link = $(element)
    form_id = link.data 'form'
    form = $(document.getElementById form_id)
    # Hide non initial forms
    if initial != form_id
      form.hide()
      link.show()
    # Add on-click function to link
    link.click (event) ->
      event.preventDefault()
      show this
    return

  # Focus on initial form
  focus $(document.getElementById initial)
  return
