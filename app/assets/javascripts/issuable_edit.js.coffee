class @IssuableEdit
  constructor: ->
    @removeEventListeners()
    @initEventListeners()

    new GLForm $('.js-issuable-inline-form')

  removeEventListeners: ->
    $(document).off 'click', '.js-issuable-title'
    $(document).off 'blur', '.js-issuable-edit-title'
    $(document).off 'click', '.js-issuable-description'
    $(document).off 'blur', '.js-task-list-field'
    $(document).off 'click', '.js-issuable-title-save'

  initEventListeners: ->
    # Title field
    $(document).on 'click', '.js-issuable-title', @showTitleEdit
    $(document).on 'blur', '.js-issuable-edit-title', @hideTitleEdit
    $(document).on 'click', '.js-issuable-title-save', @saveTitle

    # Description field
    $(document).on 'click', '.js-issuable-description', @showDescriptionEdit
    $(document).on 'blur', '.js-task-list-field', @hideDescriptionEdit

  showTitleEdit: ->
    $(this).addClass 'hidden'
    $('.js-issuable-edit-title')
      .removeClass 'hidden'
    $('.js-issuable-title-field')
      .focus()

  hideTitleEdit: (e) ->
    if $(e.currentTarget).is ':not(.js-issuable-edit-title)'
      $('.js-issuable-edit-title').addClass 'hidden'
      $('.js-issuable-title').removeClass 'hidden'

  saveTitle: (e) =>
    e.preventDefault()
    title = $('.js-issuable-title-field').val()

    # Hide the edit form
    @hideTitleEdit(e)

    $('.js-issuable-title-loading').removeClass 'hidden'
    @postData(
      issue:
        title: title
    ).done (data) ->
      $('.js-issuable-title').text data.title
      $('.js-issuable-title-loading').addClass 'hidden'

  showDescriptionEdit: ->
    $(this).addClass 'hidden'
    $('.js-issuable-description-field')
      .removeClass 'hidden'
    $('.js-task-list-field')
      .focus()

  hideDescriptionEdit: ->
    $('.js-issuable-description-field').addClass 'hidden'
    $('.js-issuable-description').removeClass 'hidden'

  postData: (data) ->
    $.ajax(
      url: $('.js-issuable-inline-form').attr('action')
      type: 'PATCH'
      dataType: 'json'
      data: data
    )
