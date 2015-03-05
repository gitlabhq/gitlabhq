class @Dashboard
  constructor: ->
    @initSidebarTab()
    new ProjectsList()

  initSidebarTab: ->
    key = "dashboard_sidebar_filter"

    # store selection in cookie
    $('.dash-sidebar-tabs a').on 'click', (e) ->
      $.cookie(key, $(e.target).attr('id'))

    # show tab from cookie
    sidebar_filter = $.cookie(key)
    $("#" + sidebar_filter).tab('show') if sidebar_filter
