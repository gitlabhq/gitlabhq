class @IssuableForm
  constructor: (@form) ->
    @titleField       = @form.find("input[name*='[title]']")
    @descriptionField = @form.find("textarea[name*='[description]']")

    return unless @titleField.length && @descriptionField.length

    @initAutosave()

    @form.on "submit", @resetAutosave
    @form.on "click", ".btn-cancel", @resetAutosave

  initAutosave: ->
    new Autosave @titleField, [
      document.location.pathname,
      document.location.search,
      "title"
    ]

    new Autosave @descriptionField, [
      document.location.pathname,
      document.location.search,
      "description"
    ]

  resetAutosave: =>
    @titleField.data("autosave").reset()
    @descriptionField.data("autosave").reset()
