# UserTabs
#
# Handles persisting and restoring the current tab selection and lazily-loading
# content on the Users#show page.
#
# ### Example Markup
#
#   <ul class="nav-links">
#     <li class="activity-tab active">
#       <a data-action="activity" data-target="#activity" data-toggle="tab" href="/u/username">
#         Activity
#       </a>
#     </li>
#     <li class="groups-tab">
#       <a data-action="groups" data-target="#groups" data-toggle="tab" href="/u/username/groups">
#         Groups
#       </a>
#     </li>
#     <li class="contributed-tab">
#       <a data-action="contributed" data-target="#contributed" data-toggle="tab" href="/u/username/contributed">
#         Contributed projects
#       </a>
#     </li>
#     <li class="projects-tab">
#       <a data-action="projects" data-target="#projects" data-toggle="tab" href="/u/username/projects">
#         Personal projects
#       </a>
#     </li>
#   </ul>
#
#   <div class="tab-content">
#     <div class="tab-pane" id="activity">
#       Activity Content
#     </div>
#     <div class="tab-pane" id="groups">
#       Groups Content
#     </div>
#     <div class="tab-pane" id="contributed">
#       Contributed projects content
#     </div>
#     <div class="tab-pane" id="projects">
#       Projects content
#     </div>
#   </div>
#
#   <div class="loading-status">
#     <div class="loading">
#       Loading Animation
#     </div>
#   </div>
#
class @UserTabs
  constructor: (opts) ->
    {
      @action = 'activity'
      @defaultAction = 'activity'
      @parentEl = $(document)
    } = opts

    # Make jQuery object if selector is provided
    @parentEl = $(@parentEl) if typeof @parentEl is 'string'

    # Store the `location` object, allowing for easier stubbing in tests
    @_location = location

    # Set tab states
    @loaded = {}
    for item in @parentEl.find('.nav-links a')
      @loaded[$(item).attr 'data-action'] = false

    # Actions
    @actions = Object.keys @loaded

    @bindEvents()

    # Set active tab
    @action = @defaultAction if @action is 'show'
    @activateTab(@action)

  bindEvents: ->
    # Toggle event listeners
    @parentEl
      .off 'shown.bs.tab', '.nav-links a[data-toggle="tab"]'
      .on 'shown.bs.tab', '.nav-links a[data-toggle="tab"]', @tabShown

  tabShown: (event) =>
    $target = $(event.target)
    action = $target.data('action')
    source = $target.attr('href')

    @setTab(source, action)
    @setCurrentAction(action)

  activateTab: (action) ->
    @parentEl.find(".nav-links .#{action}-tab a").tab('show')

  setTab: (source, action) ->
    return if @loaded[action] is true

    if action is 'activity'
      @loadActivities(source)

    if action in ['groups', 'contributed', 'projects']
      @loadTab(source, action)

  loadTab: (source, action) ->
    $.ajax
      beforeSend: => @toggleLoading(true)
      complete:   => @toggleLoading(false)
      dataType: 'json'
      type: 'GET'
      url: "#{source}.json"
      success: (data) =>
        tabSelector = 'div#' + action
        @parentEl.find(tabSelector).html(data.html)
        @loaded[action] = true

  loadActivities: (source) ->
    return if @loaded['activity'] is true

    $calendarWrap = @parentEl.find('.user-calendar')
    $calendarWrap.load($calendarWrap.data('href'))

    new Activities()
    @loaded['activity'] = true

  toggleLoading: (status) ->
    @parentEl.find('.loading-status .loading').toggle(status)

  setCurrentAction: (action) ->
    # Remove possible actions from URL
    regExp = new RegExp('\/(' + @actions.join('|') + ')(\.html)?\/?$')
    new_state = @_location.pathname
    new_state = new_state.replace(/\/+$/, "") # remove trailing slashes
    new_state = new_state.replace(regExp, '')

    # Append the new action if we're on a tab other than 'activity'
    unless action == @defaultAction
      new_state += "/#{action}"

    # Ensure parameters and hash come along for the ride
    new_state += @_location.search + @_location.hash

    history.replaceState {turbolinks: true, url: new_state}, document.title, new_state

    new_state
