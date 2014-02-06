window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

window.showAndHide = (selector) ->

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

window.sanitize = (str) ->
  return str.replace(/<(?:.|\n)*?>/gm, '')

window.linkify = (str) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return str.replace(exp,"<a href='$1'>$1</a>")

window.simpleFormat = (str) ->
  linkify(sanitize(str).replace(/\n/g, '<br />'))

window.startSpinner = ->
  $('.turbolink-spinner').fadeIn()

window.stopSpinner = ->
  $('.turbolink-spinner').fadeOut()

window.unbindEvents = ->
  $(document).unbind('scroll')
  $(document).off('scroll')

document.addEventListener("page:fetch", startSpinner)
document.addEventListener("page:fetch", unbindEvents)
document.addEventListener("page:change", stopSpinner)

$ ->
  # Click a .one_click_select field, select the contents
  $(".one_click_select").on 'click', -> $(@).select()

  $('.remove-row').bind 'ajax:success', ->
    $(this).closest('li').fadeOut()

  # Click a .appear-link, appear-data fadeout
  $(".appear-link").on 'click', (e) ->
    $('.appear-data').fadeIn()
    e.preventDefault()

  # Initialize select2 selects
  $('select.select2').select2(width: 'resolve', dropdownAutoWidth: true)

  # Initialize tooltips
  $('.has_tooltip').tooltip()

  # Bottom tooltip
  $('.has_bottom_tooltip').tooltip(placement: 'bottom')

  # Form submitter
  $('.trigger-submit').on 'change', ->
    $(@).parents('form').submit()

  $("abbr.timeago").timeago()
  $('.js-timeago').timeago()

  # Flash
  if (flash = $(".flash-container")).length > 0
    flash.click -> $(@).fadeOut()
    flash.show()
    setTimeout (-> flash.fadeOut()), 5000

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
      when 63
        new Shortcuts()
        e.preventDefault()


  # Commit show suppressed diff
  $(".content").on "click", ".supp_diff_link", ->
    $(@).next('table').show()
    $(@).remove()

  $(".content").on "click", ".js-details-expand", ->
    $(@).next('.js-details-contain').removeClass("hide")
    $(@).remove()

(($) ->
  # Disable an element and add the 'disabled' Bootstrap class
  $.fn.extend disable: ->
    $(@).attr('disabled', 'disabled').addClass('disabled')

  # Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend enable: ->
    $(@).removeAttr('disabled').removeClass('disabled')

)(jQuery)
