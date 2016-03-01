class @UserTabs
  actions: ['activity', 'groups', 'contributed', 'projects'],
  defaultAction: 'activity',

  constructor: (@opts = {}) ->
    # Store the `location` object, allowing for easier stubbing in tests
    @_location = location
    @loaded = {}

    @bindEvents()
    @tabStateInit()

    action = @opts.action
    action = @defaultAction if action == 'show'

    # Set active tab
    source = $(".#{action}-tab a").attr('href')
    @activateTab(action)

  bindEvents: ->
    $(document).on 'shown.bs.tab', '.nav-links a[data-toggle="tab"]', @tabShown

  tabStateInit: ->
    for action in @actions
      @loaded[action] = false

  tabShown: (event) =>
    $target = $(event.target)
    action = $target.data('action')
    source = $target.attr('href')

    @setTab(source, action)
    @setCurrentAction(action)

  activateTab: (action) ->
    $(".nav-links .#{action}-tab a").tab('show')

  setTab: (source, action) ->
    return if @loaded[action] is true

    if action is 'activity'
      @loadActivities(source)

    if action is 'groups'
      @loadTab(source, action)

    if action is 'contributed'
      @loadTab(source, action)

    if action is 'projects'
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
        document.querySelector(tabSelector).innerHTML = data.html
        @loaded[action] = true

  loadActivities: (source) ->
    return if @loaded['activity'] is true

    $calendarWrap = $('.user-calendar')
    $calendarWrap.load($calendarWrap.data('href'))

    new Activities()
    @loaded['activity'] = true

  toggleLoading: (status) ->
    $('.loading-status .loading').toggle(status)

  setCurrentAction: (action) ->
    # Remove possible actions from URL
    regExp = new RegExp('\/(' + @actions.join('|') + ')(\.html)?\/?$')
    new_state = @_location.pathname.replace(regExp, '')

    # Append the new action if we're on a tab other than 'activity'
    unless action == @defaultAction
      new_state += "/#{action}"

    # Ensure parameters and hash come along for the ride
    new_state += @_location.search + @_location.hash

    history.replaceState {turbolinks: true, url: new_state}, document.title, new_state

    new_state
