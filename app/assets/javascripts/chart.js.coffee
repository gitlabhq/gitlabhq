@Chart =
  labels: []
  values: []

  init: (labels, values, title) ->
    r = Raphael('activity-chart')

    fin = ->
      @flag = r.popup(@bar.x, @bar.y, @bar.value or "0").insertBefore(this) unless @hasOwnProperty("flag")
      @flag.attr "opacity", 1

    fout = ->
      @flag.animate
        opacity: 0, 300

    r.text(160, 10, title).attr font: "13px sans-serif"
    r.barchart(
      10, 20, 560, 200,
      [values],
      {colors:["#456"]}
    ).label(labels, true)
      .hover(fin, fout)
