class @UserTabs
  actions: ['activity', 'groups', 'contributed', 'personal'],
  defaultAction: 'activity',

  constructor: ->
    # Store the `location` object, allowing for easier stubbing in tests
    @_location = location

    @bindEvents()

  bindEvents: ->
    $(document).on 'shown.bs.tab', '.nav-links a[data-toggle="tab"]', @tabShown

  tabShown: (event) =>
    $target = $(event.target)
    action = $target.data('action')
    source = $target.attr('href')

    @loadTab(source, action)
    @setCurrentAction(action)

  loadTab: (source, action) ->
    @_get
      url: "#{source}.json"
      success: (data) =>
        tabSelector = 'div#' + action
        document.querySelector(tabSelector).innerHTML = data.html

  toggleLoading: (status) ->
    $('.loading-status .loading').toggle(status)

  _get: (options) ->
    defaults = {
      beforeSend: => @toggleLoading(true)
      complete:   => @toggleLoading(false)
      dataType: 'json'
      type: 'GET'
    }

    options = $.extend({}, defaults, options)

    $.ajax(options)

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
