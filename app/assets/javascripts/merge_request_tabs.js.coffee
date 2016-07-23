# MergeRequestTabs
#
# Handles persisting and restoring the current tab selection and lazily-loading
# content on the MergeRequests#show page.
#
#= require jquery.cookie
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
      @expandView()
    else if action == 'diffs'
      @loadDiff($target.attr('href'))
      if bp? and bp.getBreakpointSize() isnt 'lg'
        @shrinkView()

      navBarHeight = $('.navbar-gitlab').outerHeight()
      $.scrollTo(".merge-request-details .merge-request-tabs", offset: -navBarHeight)
    else if action == 'builds'
      @loadBuilds($target.attr('href'))
      @expandView()
    else if action == 'pipelines'
      @loadPipelines($target.attr('href'))
      @expandView()
    else
      @expandView()

    @setCurrentAction(action)

  scrollToElement: (container) ->
    if window.location.hash
      navBarHeight = $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight()

      $el = $("#{container} #{window.location.hash}:not(.match)")
      $.scrollTo("#{container} #{window.location.hash}:not(.match)", offset: -navBarHeight) if $el.length

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
    new_state = @_location.pathname.replace(/\/(commits|diffs|builds|pipelines)(\.html)?\/?$/, '')

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
        gl.utils.localTimeAgo($('.js-timeago', 'div#commits'))
        @commitsLoaded = true
        @scrollToElement("#commits")

  loadDiff: (source) ->
    return if @diffsLoaded
    @_get
      url: "#{source}.json" + @_location.search
      success: (data) =>
        $('#diffs').html data.html
        gl.utils.localTimeAgo($('.js-timeago', 'div#diffs'))
        $('#diffs .js-syntax-highlight').syntaxHighlight()
        $('#diffs .diff-file').singleFileDiff()
        @expandViewContainer() if @diffViewType() is 'parallel'
        @diffsLoaded = true
        @scrollToElement("#diffs")
        @highlighSelectedLine()
        @filesCommentButton = $('.files .diff-file').filesCommentButton()

        $(document)
          .off 'click', '.diff-line-num a'
          .on 'click', '.diff-line-num a', (e) =>
            e.preventDefault()
            window.location.hash = $(e.currentTarget).attr 'href'
            @highlighSelectedLine()
            @scrollToElement("#diffs")

  highlighSelectedLine: ->
    $('.hll').removeClass 'hll'
    locationHash = window.location.hash

    if locationHash isnt ''
      hashClassString = ".#{locationHash.replace('#', '')}"
      $diffLine = $("#{locationHash}:not(.match)", $('#diffs'))

      if not $diffLine.is 'tr'
        $diffLine = $('#diffs').find("td#{locationHash}, td#{hashClassString}")
      else
        $diffLine = $diffLine.find('td')

      if $diffLine.length
        $diffLine.addClass 'hll'
        diffLineTop = $diffLine.offset().top
        navBarHeight = $('.navbar-gitlab').outerHeight()

  loadBuilds: (source) ->
    return if @buildsLoaded

    @_get
      url: "#{source}.json"
      success: (data) =>
        document.querySelector("div#builds").innerHTML = data.html
        gl.utils.localTimeAgo($('.js-timeago', 'div#builds'))
        @buildsLoaded = true
        @scrollToElement("#builds")

  loadPipelines: (source) ->
    return if @pipelinesLoaded

    @_get
      url: "#{source}.json"
      success: (data) =>
        document.querySelector("div#pipelines").innerHTML = data.html
        gl.utils.localTimeAgo($('.js-timeago', 'div#pipelines'))
        @pipelinesLoaded = true
        @scrollToElement("#pipelines")

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
    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is expanded
      if $gutterIcon.is('.fa-angle-double-right')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)

  # Expand the issuable sidebar unless the user explicitly collapsed it
  expandView: ->
    return if $.cookie('collapsed_gutter') == 'true'

    $gutterIcon = $('.js-sidebar-toggle i:visible')

    # Wait until listeners are set
    setTimeout( ->
      # Only when sidebar is collapsed
      if $gutterIcon.is('.fa-angle-double-left')
        $gutterIcon.closest('a').trigger('click', [true])
    , 0)
