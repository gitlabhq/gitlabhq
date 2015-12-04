class @NewCommitForm
  constructor: (form) ->
    @newBranch = form.find('.js-new-branch')
    @originalBranch = form.find('.js-original-branch')
    @createMergeRequest = form.find('.js-create-merge-request')
    @createMergeRequestFormGroup = form.find('.js-create-merge-request-form-group')

    @renderDestination()
    @newBranch.keyup @renderDestination

  renderDestination: =>
    different = @newBranch.val() != @originalBranch.val()

    if different
      @createMergeRequestFormGroup.show()
      @createMergeRequest.prop('checked', true) unless @wasDifferent
    else
      @createMergeRequestFormGroup.hide()
      @createMergeRequest.prop('checked', false)

    @wasDifferent = different
