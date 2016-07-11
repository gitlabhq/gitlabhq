class @Activities
  constructor: ->
    Pager.init 20, true, false, @updateTooltips
    $(".event-filter-link").on "click", (event) =>
      event.preventDefault()
      @toggleFilter($(event.currentTarget))
      @reloadActivities()

  updateTooltips: ->
    gl.utils.localTimeAgo($('.js-timeago', '#activity'))

  reloadActivities: ->
    $(".content_list").html ''
    Pager.init 20, true


  toggleFilter: (sender) ->
    unless sender.closest('li').hasClass('active')
      $('.event-filter .active').removeClass "active"
      event_filters = $.cookie("event_filter")
      filter = sender.attr("id").split("_")[0]
      $.cookie "event_filter", (if event_filters isnt filter then filter else "all"), { path: '/' }

      if event_filters isnt filter
        sender.closest('li').toggleClass "active"
