class @GLForm
  constructor: (@form) ->
    @textarea = @form.find('textarea.js-gfm-input')

    # Before we start, we should clean up any previous data for this form
    @destroy()

    # Setup the form
    @setupForm()

    @form.data 'gl-form', @

  destroy: ->
    # Destroy actions
    actions = @form.data 'form-actions'

    if actions?
      actions.clearEventListeners()
      @form.data 'form-actions', null

    # Clean form listeners
    @clearEventListeners()
    @form.data 'gl-form', null

  setupForm: ->
    isNewForm = @form.is(':not(.gfm-form)')

    @form.removeClass 'js-new-note-form'

    if isNewForm
      @form.find('.div-dropzone').remove()
      @form.addClass('gfm-form')
      disableButtonIfEmptyField @form.find('.js-note-text'), @form.find('.js-comment-button')

      # remove notify commit author checkbox for non-commit notes
      GitLab.GfmAutoComplete.setup()
      new DropzoneInput(@form)

      autosize(@textarea)

      # Setup action buttons
      actions = new GLFormActions @form, @textarea
      @form.data 'form-actions', actions

      # form and textarea event listeners
      @addEventListeners()

    # hide discard button
    @form.find('.js-note-discard').hide()

    @form.show()

  clearEventListeners: ->
    @textarea.off 'focus'
    @textarea.off 'blur'

  addEventListeners: ->
    @textarea.on 'focus', ->
      $(@).closest('.md-area').addClass 'is-focused'

    @textarea.on 'blur', ->
      $(@).closest('.md-area').removeClass 'is-focused'
