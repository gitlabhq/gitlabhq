class @IssuableEdit
  constructor: ->
    @getElements()
    @removeEventListeners()
    @initEventListeners()

    new GLForm(@$form)

  getElements: ->
    @$form = $('.js-issuable-inline-form')
    @$details = $('.js-issuable-details')
    @$title = $('.js-issuable-title')
    @$description = $('.js-issuable-description')
    @$taskList = $('.detail-page-description .js-task-list-container')

  removeEventListeners: ->
    $(document).off 'ajax:success', '.js-issuable-inline-form', @afterSave

    $(document).off 'click', '.js-inline-edit', @toggleForm
    $(document).off 'click', '.js-issuable-edit-cancel', @toggleForm

  initEventListeners: ->
    $(document).on 'ajax:success', '.js-issuable-inline-form', @afterSave

    $(document).on 'click', '.js-inline-edit', @toggleForm
    $(document).on 'click', '.js-issuable-edit-cancel', @toggleForm

  toggleForm: =>
    @$details.toggleClass('hidden')
    @$form.toggleClass('hidden')

  afterSave: (e, data) =>
    $('[type="submit"]', @$form).enable()

    @toggleForm()

    # Update the HTML
    # We need HTML returned so that the markdown can be correctly created on server side
    @$title.html data.title
    @$description.html data.description

    @$taskList.taskList('enable')
