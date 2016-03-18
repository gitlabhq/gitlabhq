class @IssuableForm
  wipRegex: /^\s*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i
  constructor: (@form) ->
    GitLab.GfmAutoComplete.setup()
    new UsersSelect()
    new ZenMode()

    @titleField       = @form.find("input[name*='[title]']")
    @descriptionField = @form.find("textarea[name*='[description]']")

    return unless @titleField.length && @descriptionField.length

    @initAutosave()

    @form.on "submit", @resetAutosave
    @form.on "click", ".btn-cancel", @resetAutosave

    @initWip()

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

  initWip: ->
    @$wipExplanation = @form.find(".js-wip-explanation")
    @$noWipExplanation = @form.find(".js-no-wip-explanation")
    return unless @$wipExplanation.length and @$noWipExplanation.length

    @form.on "click", ".js-toggle-wip", @toggleWip

    @titleField.on "keyup blur", @renderWipExplanation

    @renderWipExplanation()

  workInProgress: ->
    @wipRegex.test @titleField.val()

  renderWipExplanation: =>
    if @workInProgress()
      @$wipExplanation.show()
      @$noWipExplanation.hide()
    else
      @$wipExplanation.hide()
      @$noWipExplanation.show()

  toggleWip: (event) =>
    event.preventDefault()

    if @workInProgress()
      @removeWip()
    else
      @addWip()

    @renderWipExplanation()

  removeWip: ->
    @titleField.val @titleField.val().replace(@wipRegex, "")

  addWip: ->
    @titleField.val "WIP: #{@titleField.val()}"
