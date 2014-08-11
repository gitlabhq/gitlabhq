class Labels
  constructor: ->
    # find the form
    form = $('.label-form')
    @setupLabelForm(form)

  ###
  General note form setup.

  deactivates the submit button when text is empty
  hides the preview button when text is empty
  setup GFM auto complete
  show the form
  ###
  setupLabelForm: (form) ->
    disableButtonIfEmptyField form, '.form-control', form.find('.js-save-button')

@Labels = Labels
