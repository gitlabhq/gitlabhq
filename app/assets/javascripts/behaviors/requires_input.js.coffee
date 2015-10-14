# Requires Input behavior
#
# When called on a form with input fields with the `required` attribute, the
# form's submit button will be disabled until all required fields have values.
#
#= require extensions/jquery
#
# ### Example Markup
#
#   <form class="js-requires-input">
#     <input type="text" required="required">
#     <input type="submit" value="Submit">
#   </form>
#
$.fn.requiresInput = ->
  $form   = $(this)
  $button = $('button[type=submit], input[type=submit]', $form)

  required      = '[required=required]'
  fieldSelector = "input#{required}, select#{required}, textarea#{required}"

  requireInput = ->
    # Collect the input values of *all* required fields
    values = _.map $(fieldSelector, $form), (field) -> field.value

    # Disable the button if any required fields are empty
    if values.length && _.any(values, _.isEmpty)
      $button.disable()
    else
      $button.enable()

  # Set initial button state
  requireInput()

  $form.on 'change input', fieldSelector, requireInput

$ ->
  $('form.js-requires-input').requiresInput()
