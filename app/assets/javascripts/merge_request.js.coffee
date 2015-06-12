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
  constructor: (@opts) ->
    @initContextWidget()
    this.$el = $('.merge-request')

    @diffs_loaded = @opts.diffs_loaded or @opts.action == 'diffs'
    @commits_loaded = @opts.commits_loaded or false

    this.bindEvents()
    this.activateTabFromPath()

    this.$('.show-all-commits').on 'click', =>
      this.showAllCommits()

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
