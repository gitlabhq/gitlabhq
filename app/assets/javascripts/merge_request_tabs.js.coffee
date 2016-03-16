# MergeRequestTabs
#
# Handles persisting and restoring the current tab selection and lazily-loading
# content on the MergeRequests#show page.
#
# ### Example Markup
#
#   <ul class="nav-links merge-request-tabs">
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
  buildsLoaded: false
  commitsLoaded: false

  constructor: (@opts = {}) ->
    # Store the `location` object, allowing for easier stubbing in tests
    @_location = location

    @bindEvents()
    @activateTab(@opts.action)

  bindEvents: ->
    $(document).on 'shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', @tabShown
    $(document).on 'click', '.js-show-tab', @showTab

  showTab: (event) =>
    event.preventDefault()

    @activateTab $(event.target).data('action')

  tabShown: (event) =>
    $target = $(event.target)
    action = $target.data('action')

    if action == 'commits'
      @loadCommits($target.attr('href'))
    else if action == 'diffs'
      @loadDiff($target.attr('href'))
      @shrinkView()
    else if action == 'builds'
      @loadBuilds($target.attr('href'))

    @setCurrentAction(action)

  scrollToElement: (container) ->
    if window.location.hash
      $el = $("div#{container} #{window.location.hash}")
      $('body').scrollTo($el.offset().top) if $el.length

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
    new_state = @_location.pathname.replace(/\/(commits|diffs|builds)(\.html)?\/?$/, '')

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
        document.querySelector("div#commits").innerHTML = data.html
        $('.js-timeago').timeago()
        @commitsLoaded = true
        @scrollToElement("#commits")

  loadDiff: (source) ->
    return if @diffsLoaded

    @_get
      url: "#{source}.json" + @_location.search
      success: (data) =>
        document.querySelector("div#diffs").innerHTML = data.html
        $('.js-timeago').timeago()
        $('div#diffs .js-syntax-highlight').syntaxHighlight()
        @expandViewContainer() if @diffViewType() is 'parallel'
        @diffsLoaded = true
        @scrollToElement("#diffs")

  loadBuilds: (source) ->
    return if @buildsLoaded

    @_get
      url: "#{source}.json"
      success: (data) =>
        document.querySelector("div#builds").innerHTML = data.html
        $('.js-timeago').timeago()
        @buildsLoaded = true
        @scrollToElement("#builds")

  # Show or hide the loading spinner
  #
  # status - Boolean, true to show, false to hide
  toggleLoading: (status) ->
    $('.mr-loading-status .loading').toggle(status)

  _get: (options) ->
    defaults = {
      beforeSend: => @toggleLoading(true)
      complete:   => @toggleLoading(false)
      dataType: 'json'
      type: 'GET'
    }

    options = $.extend({}, defaults, options)

    $.ajax(options)

  # Returns diff view type
  diffViewType: ->
    $('.inline-parallel-buttons a.active').data('view-type')

  expandViewContainer: ->
    $('.container-fluid').removeClass('container-limited')

  shrinkView: ->
    $gutterIcon = $('.js-sidebar-toggle i')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is collapsed
      if $gutterIcon.is('.fa-angle-double-right')
        $gutterIcon.closest('a').trigger('click',[true])
    , 0)
