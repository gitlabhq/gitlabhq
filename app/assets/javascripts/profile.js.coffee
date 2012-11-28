$ ->
  $('.edit-user .application-theme input, .edit-user .code-preview-theme input').click ->
    # Hide any previous submission feedback
    $('.edit-user .update-feedback').hide()

    # Submit the form
    $('.edit-user').submit()

    # Go up the hierarchy and show the corresponding submission feedback element
    $(@).closest('fieldset').find('.update-feedback').show('highlight', {color: '#DFF0D8'}, 500)
