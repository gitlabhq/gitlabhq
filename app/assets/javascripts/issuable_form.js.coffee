class @IssuableForm
  ISSUE_MOVE_CONFIRM_MSG = 'Are you sure you want to move this issue to another project?'

  constructor: (@form) ->
    GitLab.GfmAutoComplete.setup()
    new UsersSelect()
    new ZenMode()

    @titleField       = @form.find("input[name*='[title]']")
    @descriptionField = @form.find("textarea[name*='[description]']")
    @issueMoveField   = @form.find("#move_to_project_id")

    return unless @titleField.length && @descriptionField.length

    @initAutosave()

    @form.on "submit", @handleSubmit
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

  handleSubmit: =>
    if (parseInt(@issueMoveField?.val()) ? 0) > 0
      return false unless confirm(ISSUE_MOVE_CONFIRM_MSG)

    @resetAutosave()

  resetAutosave: =>
    @titleField.data("autosave").reset()
    @descriptionField.data("autosave").reset()
