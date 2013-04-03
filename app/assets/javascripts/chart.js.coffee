@Chart =
  labels: []
  values: []

  init: (labels, values, title) ->
    r = Raphael('activity-chart')
    r.text(160, 10, title).attr font: "13px sans-serif"
    r.barchart(
      10, 10, 400, 160,
      [values],
      {colors:["#456"]}
    ).label(labels, true)
