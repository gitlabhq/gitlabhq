$ ->
  $('input#broadcast_message_color').on 'input', ->
    previewColor = $(@).val()
    $('div.broadcast-message-preview').css('background-color', previewColor)

  $('input#broadcast_message_font').on 'input', ->
    previewColor = $(@).val()
    $('div.broadcast-message-preview').css('color', previewColor)

  previewPath = $('textarea#broadcast_message_message').data('preview-path')

  $('textarea#broadcast_message_message').on 'input', ->
    message = $(@).val()

    if message == ''
      $('.js-broadcast-message-preview').text("Your message here")
    else
      $.ajax(
        url: previewPath
        type: "POST"
        data: { broadcast_message: { message: message } }
      )
