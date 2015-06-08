#= require jquery.waitforimages
#= require task_list

class @MergeRequest
  # Initialize MergeRequest behavior
  #
  # Options:
  #   action         - String, current controller action
  #   diffs_loaded   - Boolean, have diffs been pre-rendered server-side?
  #                    (default: true if `action` is 'diffs', otherwise false)
  #   commits_loaded - Boolean, have commits been pre-rendered server-side?
  #                    (default: false)
  #
  #   check_enable           - Boolean, whether to check automerge status
  #   url_to_automerge_check - String, URL to use to check automerge status
  #   current_status         - String, current automerge status
  #   ci_enable              - Boolean, whether a CI service is enabled
  #   url_to_ci_check        - String, URL to use to check CI status
  #
  constructor: (@opts) ->
    @initContextWidget()
    this.$el = $('.merge-request')

    @diffs_loaded = @opts.diffs_loaded or @opts.action == 'diffs'
    @commits_loaded = @opts.commits_loaded or false

    this.bindEvents()
    this.activateTabFromPath()

    this.initMergeWidget()
    this.$('.show-all-commits').on 'click', =>
      this.showAllCommits()

    modal = $('#modal_merge_info').modal(show: false)

    disableButtonIfEmptyField '#commit_message', '.accept_merge_request'

    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

    $('.merge-request-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')

  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  initContextWidget: ->
    $('.edit-merge_request.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#merge_request_assignee_id", ->
      $(this).submit()

  initMergeWidget: ->
    this.showState( @opts.current_status )

    if this.$('.automerge_widget').length and @opts.check_enable
      $.get @opts.url_to_automerge_check, (data) =>
        this.showState( data.merge_status )
      , 'json'

    if @opts.ci_enable
      $.get @opts.url_to_ci_check, (data) =>
        this.showCiState data.status
        if data.coverage
          this.showCiCoverage data.coverage
      , 'json'

  bindEvents: ->
    this.$('.merge-request-tabs a[data-toggle="tab"]').on 'shown.bs.tab', (e) =>
      $target = $(e.target)
      tab_action = $target.data('action')

      # Lazy-load diffs
      if tab_action == 'diffs'
        this.loadDiff() unless @diffs_loaded
        $('.diff-header').trigger('sticky_kit:recalc')

      # Skip tab-persisting behavior on MergeRequests#new
      unless @opts.action == 'new'
        @setCurrentAction(tab_action)

    this.$('.accept_merge_request').on 'click', ->
      $('.automerge_widget.can_be_merged').hide()
      $('.merge-in-progress').show()

    this.$('.remove_source_branch').on 'click', ->
      $('.remove_source_branch_widget').hide()
      $('.remove_source_branch_in_progress').show()

    this.$(".remove_source_branch").on "ajax:success", (e, data, status, xhr) ->
      location.reload()

    this.$(".remove_source_branch").on "ajax:error", (e, data, status, xhr) =>
      this.$('.remove_source_branch_widget').hide()
      this.$('.remove_source_branch_in_progress').hide()
      this.$('.remove_source_branch_widget.failed').show()

  # Activate a tab based on the current URL path
  #
  # If the current action is 'show' or 'new' (i.e., initial page load),
  # activates the first tab, otherwise activates the tab corresponding to the
  # current action (diffs, commits).
  activateTabFromPath: ->
    if @opts.action == 'show' || @opts.action == 'new'
      this.$('.merge-request-tabs a[data-toggle="tab"]:first').tab('show')
    else
      this.$(".merge-request-tabs a[data-action='#{@opts.action}']").tab('show')

  # Replaces the current Merge Request-specific action in the URL with a new one
  #
  # If the action is "notes", the URL is reset to the standard
  # `MergeRequests#show` route.
  #
  # Examples:
  #
  #   location.pathname # => "/namespace/project/merge_requests/1"
  #   setCurrentAction('diffs')
  #   location.pathname # => "/namespace/project/merge_requests/1/diffs"
  #
  #   location.pathname # => "/namespace/project/merge_requests/1/diffs"
  #   setCurrentAction('notes')
  #   location.pathname # => "/namespace/project/merge_requests/1"
  #
  #   location.pathname # => "/namespace/project/merge_requests/1/diffs"
  #   setCurrentAction('commits')
  #   location.pathname # => "/namespace/project/merge_requests/1/commits"
  setCurrentAction: (action) ->
    # Normalize action, just to be safe
    action = 'notes' if action == 'show'

    # Remove a trailing '/commits' or '/diffs'
    new_state = location.pathname.replace(/\/(commits|diffs)\/?$/, '')

    # Append the new action if we're on a tab other than 'notes'
    unless action == 'notes'
      new_state += "/#{action}"

    # Ensure parameters and hash come along for the ride
    new_state += location.search + location.hash

    # Replace the current history state with the new one without breaking
    # Turbolinks' history.
    #
    # See https://github.com/rails/turbolinks/issues/363
    history.replaceState {turbolinks: true, url: new_state}, '', new_state

  showState: (state) ->
    $('.automerge_widget').hide()
    $('.automerge_widget.' + state).show()

  showCiState: (state) ->
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled"
          @setMergeButtonClass('btn-danger')
        when "running", "pending"
          @setMergeButtonClass('btn-warning')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCiCoverage: (coverage) ->
    cov_html = $('<span>')
    cov_html.addClass('ci-coverage')
    cov_html.text('Coverage ' + coverage + '%')
    $('.ci_widget:visible').append(cov_html)

  loadDiff: (event) ->
    $.ajax
      type: 'GET'
      url: this.$('.merge-request-tabs .diffs-tab a').attr('href') + ".json"
      beforeSend: =>
        this.$('.mr-loading-status .loading').show()
      complete: =>
        @diffs_loaded = true
        this.$('.mr-loading-status .loading').hide()
      success: (data) =>
        this.$(".diffs").html(data.html)
      dataType: 'json'

  showAllCommits: ->
    this.$('.first-commits').remove()
    this.$('.all-commits').removeClass 'hide'

  alreadyOrCannotBeMerged: ->
    this.$('.automerge_widget').hide()
    this.$('.merge-in-progress').hide()
    this.$('.automerge_widget.already_cannot_be_merged').show()

  setMergeButtonClass: (css_class) ->
    $('.accept_merge_request').removeClass("btn-create").addClass(css_class)

  mergeInProgress: ->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) =>
        switch data.state
          when 'merged'
            location.reload()
          else
            setTimeout(merge_request.mergeInProgress, 3000)
      dataType: 'json'

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
      url: $('form.js-merge-request-update').attr('action')
      data: patchData
