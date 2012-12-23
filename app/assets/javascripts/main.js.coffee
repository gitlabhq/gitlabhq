window.updatePage = (data) ->
  $.ajax({type: "GET", url: location.href, data: data, dataType: "script"})

window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

window.errorMessage = (message) ->
  ehtml = $("<p>")
  ehtml.addClass("error_message")
  ehtml.html(message)
  ehtml

window.split = (val) ->
  return val.split( /,\s*/ )

window.extractLast = (term) ->
  return split( term ).pop()

# Disable button if text field is empty
window.disableButtonIfEmptyField = (field_selector, button_selector) ->
  field = $(field_selector)
  closest_submit = field.closest("form").find(button_selector)

  closest_submit.disable() if field.val() is ""

  field.on "input", ->
    if $(@).val() is ""
      closest_submit.disable()
    else
      closest_submit.enable()

$ ->
  # Click a .one_click_select field, select the contents
  $(".one_click_select").on 'click', -> $(@).select()

  # Initialize chosen selects
  $('select.chosen').chosen()

  # Initialize tooltips
  $('.has_tooltip').tooltip()

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')

  # Flash
  if (flash = $("#flash-container")).length > 0
    flash.click -> $(@).slideUp("slow")
    flash.slideDown "slow"
    setTimeout (-> flash.slideUp("slow")), 3000

  # Disable form buttons while a form is submitting
  $('body').on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', @)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.disable()
      else
        buttons.enable()

  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(@).toggleClass('hover')

  # Focus search field by pressing 's' key
  $(document).keypress (e) ->
    # Don't do anything if typing in an input
    return if $(e.target).is(":input")

    switch e.which
      when 115
        $("#search").focus()
        e.preventDefault()

  # Commit show suppressed diff
  $(".supp_diff_link").bind "click", ->
    $(@).next('table').show()
    $(@).remove()

(($) ->
  _chosen = $.fn.chosen
  $.fn.extend chosen: (options) ->
    default_options = search_contains: "true"
    $.extend default_options, options
    _chosen.apply @, [default_options]

  # Disable an element and add the 'disabled' Bootstrap class
  $.fn.extend disable: ->
    $(@).attr('disabled', 'disabled').addClass('disabled')

  # Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend enable: ->
    $(@).removeAttr('disabled').removeClass('disabled')

)(jQuery)
