class @Activities
  constructor: ->
    Pager.init 20, true
    $(".event-filter-link").on "click", (event) =>
      event.preventDefault()
      @toggleFilter($(event.currentTarget))
      @reloadActivities()

  reloadActivities: ->
    $(".content_list").html ''
    Pager.init 20, true


  toggleFilter: (sender) ->
    $('.event-filter .active').removeClass "active"
    event_filters = $.cookie("event_filter")
    filter = sender.attr("id").split("_")[0]
    $.cookie "event_filter", (if event_filters isnt filter then filter else ""), { path: '/' }

    if event_filters isnt filter
      sender.closest('li').toggleClass "active"
