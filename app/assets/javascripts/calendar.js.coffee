class @calendar
  options =
    month: "short"
    day: "numeric"
    year: "numeric"

  constructor: (timestamps,starting_year,starting_month,activities_path) ->
    cal = new CalHeatMap()
    cal.init
      itemName: ["commit"]
      data: timestamps
      start: new Date(starting_year, starting_month)
      domainLabelFormat: "%b"
      id: "cal-heatmap"
      domain: "month"
      subDomain: "day"
      range: 12
      tooltip: true
      domainDynamicDimension: false
      colLimit: 4
      label:
        position: "top"
      domainMargin: 1
      legend: [
        0
        1
        4
        7
      ]
      legendCellPadding: 3
      onClick: (date, count) ->
        $.ajax
          url: activities_path
          data:
            date: date

          dataType: "json"
          success: (data) ->
            $("#loading_commits").fadeIn()
            calendar.calendarOnClick data, date, count
            setTimeout (->
              $("#calendar_onclick_placeholder").fadeIn 500
              return
            ), 400
            setTimeout (->
              $("#loading_commits").hide()
              return
            ), 400
            return  
        return
    return

  @calendarOnClick: (data, date, nb)->
    $("#calendar_onclick_placeholder").hide()
    $("#calendar_onclick_placeholder").html ->
      "<span class='calendar_onclick_second'><b>" +
      ((if nb is null then "no" else nb)) + 
      "</b><span class='calendar_commit_date'> commit" + 
      ((if (nb isnt 1) then "s" else "")) + " " + 
      date.toLocaleDateString("en-US", options) + 
      "</span><hr class='calendar_onclick_hr'></span>"
    $.each data, (key, data) ->
      $.each data, (index, data) ->
        $("#calendar_onclick_placeholder").append ->
          "Pushed <b>" + ((if data is null then "no" else data)) + " commit" +
          ((if (data isnt 1) then "s" else "")) + 
          "</b> to <a href='/" + index + "'>" + 
          index + "</a><hr class='calendar_onclick_hr'>"
        return
      return
    return
