window.dashboardPage = ->
  Pager.init 20, true
  $(".event_filter_link").bind "click", (event) ->
    event.preventDefault()
    toggleFilter $(this)
    reloadActivities()

reloadActivities = ->
  $(".content_list").html ''
  Pager.init 20, true

toggleFilter = (sender) ->
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

  $.cookie "event_filter", event_filters.join(",")
