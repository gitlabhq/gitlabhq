class @IssuableEdit
  constructor: ->
    @removeEventListeners()
    @initEventListeners()

    new GLForm $('.js-issuable-inline-form')

  removeEventListeners: ->
    $(document).off 'ajax:success', '.js-issuable-inline-form'
    $(document).off 'click', '.js-issuable-title'
    $(document).off 'blur', '.js-issuable-edit-title'
    $(document).off 'click', '.js-issuable-description'
    $(document).off 'blur', '.js-task-list-field'
    $(document).off 'click', '.js-issuable-title-save'
    $(document).off 'click', '.js-issuable-description-cancel'
    $(document).off 'click', '.js-issuable-description-save'

  initEventListeners: ->
    $(document).on 'ajax:success', '.js-issuable-inline-form', @afterSave

    # Title field
    $(document).on 'click', '.js-issuable-title', @showTitleEdit
    $(document).on 'blur', '.js-issuable-edit-title', @hideTitleEdit
    $(document).on 'click', '.js-issuable-title-save', @saveTitle

    # Description field
    $(document).on 'click', '.js-issuable-description', @showDescriptionEdit
    $(document).on 'click', '.js-issuable-description-cancel', @hideDescriptionEdit
    $(document).on 'click', '.js-issuable-description-save', @saveDescription

  showTitleEdit: ->
    $(this).addClass 'hidden'
    $('.js-issuable-edit-title')
      .removeClass 'hidden'
    $('.js-issuable-title-field')
      .focus()

  hideTitleEdit: (e) ->
    unless e.relatedTarget?
      $('.js-issuable-edit-title').addClass 'hidden'
      $('.js-issuable-title').removeClass 'hidden'

  saveTitle: (e) =>
    @hideTitleEdit(e)
    $('.js-issuable-title-loading').removeClass 'hidden'

  saveDescription: (e) =>
    @hideDescriptionEdit(e)

  showDescriptionEdit: ->
    $(this).addClass 'hidden'
    $('.js-issuable-description-field')
      .removeClass 'hidden'
    $('.js-task-list-field')
      .focus()

  hideDescriptionEdit: (e) ->
    $('.js-issuable-description-field').addClass 'hidden'
    $('.js-issuable-description').removeClass 'hidden'

  afterSave: (e, data) ->
    $('.js-issuable-title-loading').addClass 'hidden'

    # Update the HTML
    # We need HTML returned so that the markdown can be correctly created on server side
    $('.js-issuable-title').html data.title
    $('.js-issuable-description').html data.description
