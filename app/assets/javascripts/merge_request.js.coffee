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
      @initMergeRequestBtnEventListeners()

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

  initMergeRequestBtnEventListeners: ->
    _this = @
    mergeRequestFailMessage = 'Unable to update this merge request at this time.'
    $('a.btn-close, a.btn-reopen').on 'click', (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      $this = $(this)
      isClose = $this.hasClass('btn-close')
      shouldSubmit = $this.hasClass('btn-comment')
      if shouldSubmit
        _this.submitNoteForm($this.closest('form'))
      $this.prop('disabled', true)
      url = $this.attr('href')
      $.ajax
        type: 'PUT',
        url: url,
        error: (jqXHR, textStatus, errorThrown) ->
          mergeRequestStatus = if isClose then 'close' else 'open'
          new Flash(mergeRequestFailMessage, 'alert')
        success: (data, textStatus, jqXHR) ->
          if data.saved
            if isClose
              $('a.btn-close').addClass('hidden')
              $('a.issuable-edit').addClass('hidden')
              $('a.btn-reopen').removeClass('hidden')
              $('div.status-box-closed').removeClass('hidden')
              $('div.status-box-open').addClass('hidden')
            else
              $('a.btn-reopen').addClass('hidden')
              $('a.issuable-edit').removeClass('hidden')
              $('a.btn-close').removeClass('hidden')
              $('div.status-box-closed').addClass('hidden')
              $('div.status-box-open').removeClass('hidden')
          else
            new Flash(mergeRequestFailMessage, 'alert')
          $this.prop('disabled', false)

  submitNoteForm: (form) =>
    noteText = form.find("textarea.js-note-text").val()
    if noteText.trim().length > 0
      form.submit()

  showAllCommits: ->
    this.$('.first-commits').remove()
    this.$('.all-commits').removeClass 'hide'

  initTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.detail-page-description .js-task-list-container', @updateTaskList

  disableTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.detail-page-description .js-task-list-container'

  # TODO (rspeicher): Make the merge request description inline-editable like a
  # note so that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['merge_request'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData
