class @ProjectAvatar
  constructor: ->
    $('.js-choose-project-avatar-button').bind 'click', ->
      form = $(this).closest('form')
      form.find('.js-project-avatar-input').click()
    $('.js-project-avatar-input').bind 'change', ->
      form = $(this).closest('form')
      filename = $(this).val().replace(/^.*[\\\/]/, '')
      form.find('.js-avatar-filename').text(filename)
