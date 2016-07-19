class @Profile
  constructor: (opts = {}) ->
    {
      @form = $('.edit-user')
    } = opts

    # Automatically submit the Preferences form when any of its radio buttons change
    $('.js-preferences-form').on 'change.preference', 'input[type=radio]', ->
      $(this).parents('form').submit()

    # Automatically submit email form when it changes
    $('#user_notification_email').on 'change', ->
      $(this).parents('form').submit()

    $('.update-username').on 'ajax:before', ->
      $('.loading-username').show()
      $(this).find('.update-success').hide()
      $(this).find('.update-failed').hide()

    $('.update-username').on 'ajax:complete', ->
      $('.loading-username').hide()
      $(this).find('.btn-save').enable()
      $(this).find('.loading-gif').hide()

    $('.update-notifications').on 'ajax:success', (e, data) ->
      if data.saved
        new Flash("Notification settings saved", "notice")
      else
        new Flash("Failed to save new settings", "alert")

    @bindEvents()

    cropOpts =
      filename: '.js-avatar-filename'
      previewImage: '.avatar-image .avatar'
      modalCrop: '.modal-profile-crop'
      pickImageEl: '.js-choose-user-avatar-button'
      uploadImageBtn: '.js-upload-user-avatar'
      modalCropImg: '.modal-profile-crop-image'

    @avatarGlCrop = $('.js-user-avatar-input').glCrop(cropOpts).data 'glcrop'

  bindEvents: ->
    @form.on 'submit', @onSubmitForm

  onSubmitForm: (e) =>
    e.preventDefault()
    @saveForm()

  saveForm: ->
    self = @
    formData = new FormData(@form[0])

    avatarBlob = @avatarGlCrop.getBlob()
    formData.append('user[avatar]', avatarBlob, 'avatar.png') if avatarBlob?

    $.ajax
      url: @form.attr('action')
      type: @form.attr('method')
      data: formData
      dataType: "json"
      processData: false
      contentType: false
      success: (response) ->
        new Flash(response.message, 'notice')
      error: (jqXHR) ->
        new Flash(jqXHR.responseJSON.message, 'alert')
      complete: ->
        window.scrollTo 0, 0
        # Enable submit button after requests ends
        self.form.find(':input[disabled]').enable()

$ ->
  # Extract the SSH Key title from its comment
  $(document).on 'focusout.ssh_key', '#key_key', ->
    $title  = $('#key_title')
    comment = $(@).val().match(/^\S+ \S+ (.+)\n?$/)

    if comment && comment.length > 1 && $title.val() == ''
      $title.val(comment[1]).change()

  if gl.utils.getPagePath() == 'profiles'
    new Profile()
