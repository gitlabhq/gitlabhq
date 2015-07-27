#= require jquery.waitforimages
#= require task_list

#= require merge_request_tabs

class @MergeRequest
  # Initialize MergeRequest behavior
  #
  # Options:
  #   action - String, current controller action
  #
  constructor: (@opts) ->
    this.$el = $('.merge-request')

    this.$('.show-all-commits').on 'click', =>
      this.showAllCommits()

    @initTabs()

    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  initTabs: ->
    if @opts.action != 'new'
      # `MergeRequests#new` has no tab-persisting or lazy-loading behavior
      new MergeRequestTabs(@opts)
    else
      # Show the first tab (Commits)
      $('.merge-request-tabs a[data-toggle="tab"]:first').tab('show')

  showAllCommits: ->
    this.$('.first-commits').remove()
    this.$('.all-commits').removeClass 'hide'

  initTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.merge-request-details .js-task-list-container', @updateTaskList

  disableTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.merge-request-details .js-task-list-container'

  # TODO (rspeicher): Make the merge request description inline-editable like a
  # note so that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['merge_request'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData
