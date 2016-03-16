class @Profile
  constructor: ->
    # Automatically submit the Preferences form when any of its radio buttons change
    $('.js-preferences-form').on 'change.preference', 'input[type=radio]', ->
      $(this).parents('form').submit()

    $('.update-username').on 'ajax:before', ->
      $('.loading-username').show()
      $(this).find('.update-success').hide()
      $(this).find('.update-failed').hide()

    $('.update-username').on 'ajax:complete', ->
      $('.loading-username').hide()
      $(this).find('.btn-save').enable()
      $(this).find('.loading-gif').hide()

    $('.update-notifications').on 'ajax:complete', ->
      $(this).find('.btn-save').enable()

    $('.js-choose-user-avatar-button').bind "click", ->
      form = $(this).closest("form")
      form.find(".js-user-avatar-input").click()

    $('.js-user-avatar-input').bind "change", ->
      form = $(this).closest("form")
      filename = $(this).val().replace(/^.*[\\\/]/, '')
      form.find(".js-avatar-filename").text(filename)

$ ->
  # Extract the SSH Key title from its comment
  $(document).on 'focusout.ssh_key', '#key_key', ->
    $title  = $('#key_title')
    comment = $(@).val().match(/^\S+ \S+ (.+)\n?$/)

    if comment && comment.length > 1 && $title.val() == ''
      $title.val(comment[1]).change()
