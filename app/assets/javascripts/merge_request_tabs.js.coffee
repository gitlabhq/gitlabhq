class @MergeRequestTabs
  diffsLoaded: false
  commitsLoaded: false

  constructor: (@opts) ->
    @bindEvents()
    @activateTabFromPath()

    switch @opts.action
      when 'commits' then @commitsLoaded = true
      when 'diffs'   then @diffsLoaded = true

  bindEvents: ->
    $(document).on 'shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', @tabShow

  tabShow: (event) =>
    $target = $(event.target)
    action = $target.data('action')

    # Lazy-load commits
    if action == 'commits' && !@commitsLoaded
      @loadCommits()

    # Lazy-load diffs
    if action == 'diffs' && !@diffsLoaded
      @loadDiff()

    @setCurrentAction(action)

  # Activate a tab based on the current URL path
  #
  # If the current action is 'show' or 'new' (i.e., initial page load),
  # activates the first tab, otherwise activates the tab corresponding to the
  # current action (diffs, commits).
  activateTabFromPath: ->
    if @opts.action == 'show' || @opts.action == 'new'
      $('.merge-request-tabs a[data-toggle="tab"]:first').tab('show')
    else
      $(".merge-request-tabs a[data-action='#{@opts.action}']").tab('show')

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
    history.replaceState {turbolinks: true, url: new_state}, document.title, new_state

  loadCommits: ->
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: $('.merge-request-tabs .commits-tab a').attr('href') + ".json"
      beforeSend: @toggleLoading
      complete: =>
        @commits_loaded = true
        @toggleLoading()
      success: (data) =>
        document.getElementById('commits').innerHTML = data.html

        $('.js-timeago').timeago()

  loadDiff: ->
    $.ajax
      type: 'GET'
      dataType: 'json'
      url: $('.merge-request-tabs .diffs-tab a').attr('href') + ".json"
      beforeSend: => @toggleLoading()
      complete: =>
        @diffs_loaded = true
        @toggleLoading()
      success: (data) =>
        document.getElementById('diffs').innerHTML = data.html

        $('.diff-header').trigger('sticky_kit:recalc')

  toggleLoading: ->
    $('.mr-loading-status .loading').toggle()
