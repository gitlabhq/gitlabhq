class @MergedButtons
  constructor: ->
    @$removeBranchWidget = $('.remove_source_branch_widget')
    @$removeBranchProgress = $('.remove_source_branch_in_progress')
    @$removeBranchFailed = $('.remove_source_branch_widget.failed')

    @cleanEventListeners()
    @initEventListeners()

  cleanEventListeners: ->
    $(document).off 'click', '.remove_source_branch'
    $(document).off 'ajax:success', '.remove_source_branch'
    $(document).off 'ajax:error', '.remove_source_branch'

  initEventListeners: ->
    $(document).on 'click', '.remove_source_branch', @removeSourceBranch
    $(document).on 'ajax:success', '.remove_source_branch', @removeBranchSuccess
    $(document).on 'ajax:error', '.remove_source_branch', @removeBranchError

  removeSourceBranch: =>
    @$removeBranchWidget.hide()
    @$removeBranchProgress.show()

  removeBranchSuccess: ->
    location.reload()

  removeBranchError: ->
    @$removeBranchWidget.hide()
    @$removeBranchProgress.hide()
    @$removeBranchFailed.show()
