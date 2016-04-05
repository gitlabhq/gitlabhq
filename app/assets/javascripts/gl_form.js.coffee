class @GLForm
  constructor: (@form) ->
    @textarea = @form.find(".js-note-text")

    @setupForm()

  setupForm: ->
    isNewForm = @form.is(':not(.gfm-form)')

    @form.removeClass "js-new-note-form"

    if isNewForm
      @form.find('.div-dropzone').remove()
      @form.addClass('gfm-form')
      disableButtonIfEmptyField @form.find(".js-note-text"), @form.find(".js-comment-button")

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

  addEventListeners: ->
    @textarea.on 'focus', ->
      $(@).closest('.md-area').addClass 'is-focused'

    @textarea.on 'blur', ->
      $(@).closest('.md-area').removeClass 'is-focused'
