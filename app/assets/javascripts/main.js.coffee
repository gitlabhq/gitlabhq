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

  closest_submit.attr("disabled", "disabled").addClass("disabled") if field.val() is ""

  field.on "keyup", ->
    if $(this).val() is ""
      closest_submit.attr("disabled", "disabled").addClass "disabled"
    else
      closest_submit.removeAttr("disabled").removeClass "disabled"

$ ->
  $(".one_click_select").live 'click', ->
    $(this).select()

  $('body').on 'ajax:complete, ajax:beforeSend, submit', 'form', (e) ->
    buttons = $('[type="submit"]', this)

    switch e.type
      when 'ajax:beforeSend', 'submit'
        buttons.attr('disabled', 'disabled')
      else
        buttons.removeAttr('disabled')

  # Show/Hide the profile menu when hovering the account box
  $('.account-box').hover -> $(this).toggleClass('hover')

  $("#projects-list .project").live 'click', (e) ->
    if e.target.nodeName isnt "A" and e.target.nodeName isnt "INPUT"
      location.href = $(this).attr("url")
      e.stopPropagation()
      false

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
    note = 'Nothing to preview' if note.trim().length is 0
    $.post($(this).attr('href'), {note: note}, (data) ->
      $('#preview-note').html(data)
    )

    $('#preview-note, #note_note').toggle()
    e.preventDefault()
    false

(($) ->
  _chosen = $.fn.chosen
  $.fn.extend chosen: (options) ->
    default_options = search_contains: "true"
    $.extend default_options, options
    _chosen.apply this, [default_options]

)(jQuery)
