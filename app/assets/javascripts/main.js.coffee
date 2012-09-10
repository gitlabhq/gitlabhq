window.updatePage = (data) ->
  $.ajax({type: "GET", url: location.href, data: data, dataType: "script"})

window.slugify = (text) ->
  text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase()

window.ajaxGet = (url) ->
  $.ajax({type: "GET", url: url, dataType: "script"})

 # Disable button if text field is empty
window.disableButtonIfEmptyField = (field_selector, button_selector) ->
  field = $(field_selector)
  closest_submit = field.closest("form").find(button_selector)

  closest_submit.disable() if field.val() is ""

  field.on "keyup", ->
    if $(this).val() is ""
      closest_submit.disable()
    else
      closest_submit.enable()

$ ->
  # Click a .one_click_select field, select the contents
  $(".one_click_select").live 'click', -> $(this).select()

  # Initialize chosen selects
  $('select.chosen').chosen()

  # Disable form buttons while a form is submitting
  $('body').on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', this)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.disable()
      else
        buttons.enable()

  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(this).toggleClass('hover')

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
    $(this).next('table').show()
    $(this).remove()

  # Note markdown preview
  $(document).on 'click', '#preview-link', (e) ->
    $('#preview-note').text('Loading...')

    previewLinkText = if $(this).text() == 'Preview' then 'Edit' else 'Preview'
    $(this).text(previewLinkText)

    note = $('#note_note').val()

    if note.trim().length == 0
      $('#preview-note').text("Nothing to preview.")
    else
      $.post $(this).attr('href'), {note: note}, (data) ->
        $('#preview-note').html(data)

    $('#preview-note, #note_note').toggle()
    e.preventDefault()
    false

(($) ->
  _chosen = $.fn.chosen
  $.fn.extend chosen: (options) ->
    default_options = search_contains: "true"
    $.extend default_options, options
    _chosen.apply this, [default_options]

  # Disable an element and add the 'disabled' Bootstrap class
  $.fn.extend disable: ->
    $(this).attr('disabled', 'disabled').addClass('disabled')

  # Enable an element and remove the 'disabled' Bootstrap class
  $.fn.extend enable: ->
    $(this).removeAttr('disabled').removeClass('disabled')

)(jQuery)
