class @calendar
  options =
    month: "short"
    day: "numeric"
    year: "numeric"

  constructor: (timestamps, starting_year, starting_month) ->
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
      label:
        position: "top"
      legend: [
        0
        1
        4
        7
      ]
      legendCellPadding: 3
      onClick: (date, count) ->
        return
    return
