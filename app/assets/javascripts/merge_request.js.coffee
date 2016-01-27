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

    @fixAffixScroll();

    @initTabs()

    # Prevent duplicate event bindings
    @disableTaskList()
    @initMRBtnListeners()

    if $("a.btn-close").length
      @initTaskList()

  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  fixAffixScroll: ->
    fixAffix = ->
      $discussion = $('.issuable-discussion')
      $sidebar = $('.issuable-sidebar')
      if $sidebar.hasClass('no-affix')
        $sidebar.removeClass(['affix-top','affix'])
      discussionHeight = $discussion.height()
      sidebarHeight = $sidebar.height()
      if sidebarHeight > discussionHeight
        $discussion.height(sidebarHeight + 50)
        $sidebar.addClass('no-affix')
    $(window).on('resize', fixAffix)
    fixAffix()

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
    $('.detail-page-description .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.detail-page-description .js-task-list-container', @updateTaskList

  initMRBtnListeners: ->
    _this = @
    $('a.btn-close, a.btn-reopen').on 'click', (e) ->
      $this = $(this)
      shouldSubmit = $this.hasClass('btn-comment')
      if shouldSubmit && $this.data('submitted')
        return
      if shouldSubmit
        if $this.hasClass('btn-comment-and-close') || $this.hasClass('btn-comment-and-reopen')
          e.preventDefault()
          e.stopImmediatePropagation()
          _this.submitNoteForm($this.closest('form'),$this)


  submitNoteForm: (form, $button) =>
    noteText = form.find("textarea.js-note-text").val()
    if noteText.trim().length > 0
      form.submit()
      $button.data('submitted',true)
      $button.trigger('click')


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
