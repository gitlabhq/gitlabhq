class @NewCommitForm
  constructor: (form) ->
    @newBranch = form.find('.js-target-branch')
    @originalBranch = form.find('.js-original-branch')
    @createMergeRequest = form.find('.js-create-merge-request')
    @createMergeRequestContainer = form.find('.js-create-merge-request-container')

    @renderDestination()
    @newBranch.keyup @renderDestination

  renderDestination: =>
    different = @newBranch.val() != @originalBranch.val()

    if different
      @createMergeRequestContainer.show()
      @createMergeRequest.prop('checked', true) unless @wasDifferent
    else
      @createMergeRequestContainer.hide()
      @createMergeRequest.prop('checked', false)

    @wasDifferent = different
