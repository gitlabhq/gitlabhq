class @Calendar
  constructor: (timestamps, starting_year, starting_month, calendar_activities_path) ->
    cal = new CalHeatMap()
    cal.init
      itemName: ["次贡献", "次贡献"]
      data: timestamps
      start: new Date(starting_year, starting_month)
      domainLabelFormat: "%-m 月"
      subDomainDateFormat: "%Y-%m-%d"
      subDomainTitleFormat:
        filled: "{date}：{count} {name}"
      id: "cal-heatmap"
      domain: "month"
      subDomain: "day"
      range: 12
      tooltip: true
      label:
        position: "top"
      legend: [
        0
        10
        20
        30
      ]
      legendCellPadding: 3
      cellSize: $('.user-calendar').width() / 73
      onClick: (date, count) ->
        formated_date = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + date.getDate()
        $.ajax
          url: calendar_activities_path
          data:
            date: formated_date
          cache: false
          dataType: "html"
          success: (data) ->
            $(".user-calendar-activities").html data

