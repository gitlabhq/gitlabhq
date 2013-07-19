class Dashboard
  constructor: ->
    Pager.init 20, true
    @initSidebarTab()

    $(".event_filter_link").bind "click", (event) =>
      event.preventDefault()
      @toggleFilter($(event.currentTarget))
      @reloadActivities()

    $(".dash-filter").keyup ->
      terms = $(this).val()
      uiBox = $(this).parents('.ui-box').first()
      if terms == "" || terms == undefined
        uiBox.find(".dash-list li").show()
      else
        uiBox.find(".dash-list li").each (index) ->
          name = $(this).find(".filter-title").text()

          if name.toLowerCase().search(terms.toLowerCase()) == -1
            $(this).hide()
          else
            $(this).show()



  reloadActivities: ->
    $(".content_list").html ''
    Pager.init 20, true

  toggleFilter: (sender) ->
    sender.parent().toggleClass "inactive"
    event_filters = $.cookie("event_filter")
    filter = sender.attr("id").split("_")[0]
    if event_filters
      event_filters = event_filters.split(",")
    else
      event_filters = new Array()

    index = event_filters.indexOf(filter)
    if index is -1
      event_filters.push filter
    else
      event_filters.splice index, 1

    $.cookie "event_filter", event_filters.join(","), { path: '/' }

  initSidebarTab: ->
    key = "dashboard_sidebar_filter"

    # store selection in cookie
    $('.dash-sidebar-tabs a').on 'click', (e) ->
      $.cookie(key, $(e.target).attr('id'))

    # show tab from cookie
    sidebar_filter = $.cookie(key)
    $("#" + sidebar_filter).tab('show') if sidebar_filter


@Dashboard = Dashboard
