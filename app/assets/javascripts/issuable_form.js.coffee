class @IssuableForm
  wipRegex: /^\[?WIP(\]|:| )\s*/i
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
    return unless @form.find(".js-wip-explanation").length
    
    @form.on "click", ".js-remove-wip", @removeWip

    @form.on "click", ".js-add-wip", @addWip

    @titleField.on "change", @renderWipExplanation

    @renderWipExplanation()

  workInProgress: ->
    @titleField.val().match(@wipRegex)

  renderWipExplanation: =>
    if @workInProgress()
      @form.find(".js-wip-explanation").show()
      @form.find(".js-no-wip-explanation").hide()
    else
      @form.find(".js-wip-explanation").hide()
      @form.find(".js-no-wip-explanation").show()

  removeWip: (event) =>
    event.preventDefault()

    return unless @workInProgress()
    @titleField.val @titleField.val().replace(@wipRegex, "")

    @renderWipExplanation()

  addWip: (event) =>
    event.preventDefault()

    return if @workInProgress()
    @titleField.val "WIP: #{@titleField.val()}"

    @renderWipExplanation()
