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

    # Avatar management

    $avatarInput = $('.js-user-avatar-input')
    $filename = $('.js-avatar-filename')
    $modalCrop = $('.modal-profile-crop')
    $modalCropImg = $('.modal-profile-crop-image')

    $('.js-choose-user-avatar-button').on "click", ->
      $form = $(this).closest("form")
      $form.find(".js-user-avatar-input").click()

    $modalCrop.on 'shown.bs.modal', ->
      setTimeout ( -> # The cropper must be asynchronously initialized
        $modalCropImg.cropper
          aspectRatio: 1
          modal: false
          scalable: false
          rotatable: false
          zoomable: false

          crop: (event) ->
            ['x', 'y'].forEach (key) ->
              $("#user_avatar_crop_#{key}").val(Math.floor(event[key]))
            $("#user_avatar_crop_size").val(Math.floor(event.width))
      ), 0

    $modalCrop.on 'hidden.bs.modal', ->
      $modalCropImg.attr('src', '').cropper('destroy')
      $avatarInput.val('')
      $filename.text($filename.data('label'))

    $('.js-upload-user-avatar').on 'click', ->
      $('.edit-user').submit()

    $avatarInput.on "change", ->
      form = $(this).closest("form")
      filename = $(this).val().replace(/^.*[\\\/]/, '')
      $filename.data('label', $filename.text()).text(filename)

      reader = new FileReader

      reader.onload = (event) ->
        $modalCrop.modal('show')
        $modalCropImg.attr('src', event.target.result)

      fileData = reader.readAsDataURL(this.files[0])

$ ->
  # Extract the SSH Key title from its comment
  $(document).on 'focusout.ssh_key', '#key_key', ->
    $title  = $('#key_title')
    comment = $(@).val().match(/^\S+ \S+ (.+)\n?$/)

    if comment && comment.length > 1 && $title.val() == ''
      $title.val(comment[1]).change()
