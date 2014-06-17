class Dashboard
  constructor: ->
    @initSidebarTab()

    $(".dash-filter").keyup ->
      terms = $(this).val()
      uiBox = $(this).parents('.panel').first()
      if terms == "" || terms == undefined
        uiBox.find(".dash-list li").show()
      else
        uiBox.find(".dash-list li").each (index) ->
          name = $(this).find(".filter-title").text()

          if name.toLowerCase().search(terms.toLowerCase()) == -1
            $(this).hide()
          else
            $(this).show()



  initSidebarTab: ->
    key = "dashboard_sidebar_filter"

    # store selection in cookie
    $('.dash-sidebar-tabs a').on 'click', (e) ->
      $.cookie(key, $(e.target).attr('id'))

    # show tab from cookie
    sidebar_filter = $.cookie(key)
    $("#" + sidebar_filter).tab('show') if sidebar_filter


@Dashboard = Dashboard
