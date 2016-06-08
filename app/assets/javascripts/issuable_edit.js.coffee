class @IssuableEdit
  constructor: ->
    @getElements()
    @removeEventListeners()
    @initEventListeners()

    new GLForm(@elements.form)

  getElements: ->
    @elements =
      form: $('.js-issuable-inline-form')
      title:
        element: $('.js-issuable-title')
        field: $('.js-issuable-title-field')
        fieldset: $('.js-issuable-edit-title')
        loading: $('.js-issuable-title-loading')
      description:
        element: $('.js-issuable-description')
        field: $('.js-task-list-field')
        fieldset: $('.js-issuable-description-field')
        loading: $('.js-issuable-title-loading')

  removeEventListeners: ->
    $(document).off 'ajax:success', '.js-issuable-inline-form'
    $(document).off 'click', '.js-issuable-edit-cancel'

    $(document).off 'click', '.js-issuable-title'
    $(document).off 'click', '.js-issuable-title-save'

    $(document).off 'click', '.js-issuable-description'
    $(document).off 'click', '.js-issuable-description-save'

  initEventListeners: ->
    $(document).on 'ajax:success', '.js-issuable-inline-form', @afterSave
    $(document).on 'click', '.js-issuable-edit-cancel', @hideFields

    # Title field
    $(document).on 'click', '.js-issuable-title', @showTitleEdit
    $(document).on 'click', '.js-issuable-title-save', @saveTitle

    # Description field
    $(document).on 'click', '.js-issuable-description', @showDescriptionEdit
    $(document).on 'click', '.js-issuable-description-save', @saveDescription

  hideFields: (e) =>
    @hideTitleEdit(e)
    @hideDescriptionEdit(e)

  showTitleEdit: =>
    @elements.title.element.addClass 'hidden'
    @elements.title.fieldset.removeClass 'hidden'
    @elements.title.field.focus()

  hideTitleEdit: (e) ->
    @elements.title.fieldset.addClass 'hidden'
    @elements.title.element.removeClass 'hidden'

  saveTitle: (e) =>
    @hideTitleEdit()
    @elements.title.loading.removeClass 'hidden'

  saveDescription: (e) =>
    @hideDescriptionEdit(e)
    @elements.description.element.addClass 'is-loading'

  showDescriptionEdit: (e) =>
    if $(e.target).is(':not(input,a)')
      @elements.description.element.addClass 'hidden'
      @elements.description.fieldset.removeClass 'hidden'
      @elements.description.field.focus()

  hideDescriptionEdit: (e) ->
    @elements.description.fieldset.addClass 'hidden'
    @elements.description.element.removeClass 'hidden'

  afterSave: (e, data) =>
    $('.js-issuable-inline-form [type="submit"]').enable()

    @hideTitleEdit()
    @hideDescriptionEdit(e)

    @elements.title.loading.addClass 'hidden'
    @elements.description.element.removeClass 'is-loading'

    # Update the HTML
    # We need HTML returned so that the markdown can be correctly created on server side
    @elements.title.element.html data.title
    @elements.description.element.html data.description

    $('.detail-page-description .js-task-list-container').taskList('enable')
