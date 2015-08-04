# MergeRequestTabs
#
# Handles persisting and restoring the current tab selection and lazily-loading
# content on the MergeRequests#show page.
#
# ### Example Markup
#
#   <ul class="nav nav-tabs merge-request-tabs">
#     <li class="notes-tab active">
#       <a data-action="notes" data-target="#notes" data-toggle="tab" href="/foo/bar/merge_requests/1">
#         Discussion
#       </a>
#     </li>
#     <li class="commits-tab">
#       <a data-action="commits" data-target="#commits" data-toggle="tab" href="/foo/bar/merge_requests/1/commits">
#         Commits
#       </a>
#     </li>
#     <li class="diffs-tab">
#       <a data-action="diffs" data-target="#diffs" data-toggle="tab" href="/foo/bar/merge_requests/1/diffs">
#         Diffs
#       </a>
#     </li>
#   </ul>
#
#   <div class="tab-content">
#     <div class="notes tab-pane active" id="notes">
#       Notes Content
#     </div>
#     <div class="commits tab-pane" id="commits">
#       Commits Content
#     </div>
#     <div class="diffs tab-pane" id="diffs">
#       Diffs Content
#     </div>
#   </div>
#
#   <div class="mr-loading-status">
#     <div class="loading">
#       Loading Animation
#     </div>
#   </div>
#
class @MergeRequestTabs
  diffsLoaded: false
  commitsLoaded: false

  constructor: (@opts = {}) ->
    # Store the `location` object, allowing for easier stubbing in tests
    @_location = location

    @bindEvents()
    @activateTab(@opts.action)

  bindEvents: ->
    $(document).on 'shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', @tabShown

  tabShown: (event) =>
    $target = $(event.target)
    action = $target.data('action')

    if action == 'commits'
      @loadCommits($target.attr('href'))
    else if action == 'diffs'
      @loadDiff($target.attr('href'))

    @setCurrentAction(action)

  # Activate a tab based on the current action
  activateTab: (action) ->
    action = 'notes' if action == 'show'
    $(".merge-request-tabs a[data-action='#{action}']").tab('show')

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
  #
  # Returns the new URL String
  setCurrentAction: (action) =>
    # Normalize action, just to be safe
    action = 'notes' if action == 'show'

    # Remove a trailing '/commits' or '/diffs'
    new_state = @_location.pathname.replace(/\/(commits|diffs)(\.html)?\/?$/, '')

    # Append the new action if we're on a tab other than 'notes'
    unless action == 'notes'
      new_state += "/#{action}"

    # Ensure parameters and hash come along for the ride
    new_state += @_location.search + @_location.hash

    # Replace the current history state with the new one without breaking
    # Turbolinks' history.
    #
    # See https://github.com/rails/turbolinks/issues/363
    history.replaceState {turbolinks: true, url: new_state}, document.title, new_state

    new_state

  loadCommits: (source) ->
    return if @commitsLoaded

    @_get
      url: "#{source}.json"
      success: (data) =>
        document.getElementById('commits').innerHTML = data.html
        $('.js-timeago').timeago()
        @commitsLoaded = true

  loadDiff: (source) ->
    return if @diffsLoaded

    @_get
      url: "#{source}.json" + @_location.search
      success: (data) =>
        document.getElementById('diffs').innerHTML = data.html
        @diffsLoaded = true

  toggleLoading: ->
    $('.mr-loading-status .loading').toggle()

  _get: (options) ->
    defaults = {
      beforeSend: @toggleLoading
      complete: @toggleLoading
      dataType: 'json'
      type: 'GET'
    }

    options = $.extend({}, defaults, options)

    $.ajax(options)
