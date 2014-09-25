class Labels
  constructor: ->
    form = $('.label-form')
    @setupLabelForm(form)
    @cleanBinding()
    @addBinding()
    @updateColorPreview()

  addBinding: ->
    $(document).on 'click', '.suggest-colors a', @setSuggestedColor
    $(document).on 'input', 'input#label_color', @updateColorPreview

  cleanBinding: ->
    $(document).off 'click', '.suggest-colors a'
    $(document).off 'input', 'input#label_color'

  # Initializes the form to disable the save button if no color or title is entered
  setupLabelForm: (form) ->
    disableButtonIfAnyEmptyField form, '.form-control', form.find('.js-save-button')

  # Updates the the preview color with the hex-color input
  updateColorPreview: =>
    previewColor = $('input#label_color').val()
    $('div.label-color-preview').css('background-color', previewColor)

  # Updates the preview color with a click on a suggested color
  setSuggestedColor: (e) =>
    color = $(e.currentTarget).data('color')
    $('input#label_color').val(color)
    @updateColorPreview()
    # Notify the form, that color has changed
    $('.label-form').trigger('keyup')
    e.preventDefault()

@Labels = Labels
