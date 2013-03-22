class BranchGraph
  constructor: (@element, @options) ->
    @preparedCommits = {}
    @mtime = 0
    @mspace = 0
    @parents = {}
    @colors = ["#000"]
    @offsetX = 120
    @offsetY = 20
    @unitTime = 30
    @unitSpace = 10
    @load()

  load: ->
    $.ajax
      url: @options.url
      method: "get"
      dataType: "json"
      success: $.proxy((data) ->
        $(".loading", @element).hide()
        @prepareData data.days, data.commits
        @buildGraph()
      , this)

  prepareData: (@days, @commits) ->
    @collectParents()

    for c in @commits
      c.isParent = true  if c.id of @parents
      @preparedCommits[c.id] = c

    @collectColors()

  collectParents: ->
    for c in @commits
      @mtime = Math.max(@mtime, c.time)
      @mspace = Math.max(@mspace, c.space)
      for p in c.parents
        @parents[p[0]] = true
        @mspace = Math.max(@mspace, p[1])

  collectColors: ->
    k = 0
    while k < @mspace
      @colors.push Raphael.getColor(.8)
      # Skipping a few colors in the spectrum to get more contrast between colors
      Raphael.getColor()
      Raphael.getColor()
      k++

  buildGraph: ->
    graphHeight = $(@element).height()
    graphWidth = $(@element).width()
    ch = Math.max(graphHeight, @offsetY + @unitTime * @mtime + 150)
    cw = Math.max(graphWidth, @offsetX + @unitSpace * @mspace + 300)
    @r = r = Raphael(@element.get(0), cw, ch)
    top = r.set()
    cuday = 0
    cumonth = ""
    barHeight = Math.max(graphHeight, @unitTime * @days.length + 320)

    r.rect(0, 0, 26, barHeight).attr fill: "#222"
    r.rect(26, 0, 20, barHeight).attr fill: "#444"

    for day, mm in @days
      if cuday isnt day[0]
        # Dates
        r.text(36, @offsetY + @unitTime * mm, day[0])
          .attr(
            font: "12px Monaco, monospace"
            fill: "#DDD"
          )
        cuday = day[0]

      if cumonth isnt day[1]
        # Months
        r.text(13, @offsetY + @unitTime * mm, day[1])
          .attr(
            font: "12px Monaco, monospace"
            fill: "#EEE"
          )
        cumonth = day[1]

    for commit in @commits
      x = @offsetX + @unitSpace * (@mspace - commit.space)
      y = @offsetY + @unitTime * commit.time

      @drawDot(x, y, commit)

      @drawLines(x, y, commit)

      @appendLabel(x, y, commit.refs)  if commit.refs

      @appendAnchor(top, commit, x, y)

      @markCommit(x, y, commit, graphHeight)

    top.toFront()
    @bindEvents()

  bindEvents: ->
    drag = {}
    element = @element
    dragger = (event) ->
      element.scrollLeft drag.sl - (event.clientX - drag.x)
      element.scrollTop drag.st - (event.clientY - drag.y)

    element.on mousedown: (event) ->
      drag =
        x: event.clientX
        y: event.clientY
        st: element.scrollTop()
        sl: element.scrollLeft()
      $(window).on "mousemove", dragger

    $(window).on
      mouseup: ->
        $(window).off "mousemove", dragger
      keydown: (event) ->
        # left
        element.scrollLeft element.scrollLeft() - 50  if event.keyCode is 37
        # top
        element.scrollTop element.scrollTop() - 50  if event.keyCode is 38
        # right
        element.scrollLeft element.scrollLeft() + 50  if event.keyCode is 39
        # bottom
        element.scrollTop element.scrollTop() + 50  if event.keyCode is 40

  appendLabel: (x, y, refs) ->
    r = @r
    shortrefs = refs
    # Truncate if longer than 15 chars
    shortrefs = shortrefs.substr(0, 15) + "…"  if shortrefs.length > 17
    text = r.text(x + 8, y, shortrefs).attr(
      "text-anchor": "start"
      font: "10px Monaco, monospace"
      fill: "#FFF"
      title: refs
    )
    textbox = text.getBBox()
    # Create rectangle based on the size of the textbox
    rect = r.rect(x, y - 7, textbox.width + 15, textbox.height + 5, 4).attr(
      fill: "#000"
      "fill-opacity": .5
      stroke: "none"
    )
    triangle = r.path(["M", x - 5, y, "L", x - 15, y - 4, "L", x - 15, y + 4, "Z"]).attr(
      fill: "#000"
      "fill-opacity": .5
      stroke: "none"
    )

    label = r.set(rect, text)
    label.transform(["t", -rect.getBBox().width - 15, 0])

    # Set text to front
    text.toFront()

  appendAnchor: (top, commit, x, y) ->
    r = @r
    options = @options
    anchor = r.circle(x, y, 10).attr(
      fill: "#000"
      opacity: 0
      cursor: "pointer"
    ).click(->
      window.open options.commit_url.replace("%s", commit.id), "_blank"
    ).hover(->
      @tooltip = r.commitTooltip(x + 5, y, commit)
      top.push @tooltip.insertBefore(this)
    , ->
      @tooltip and @tooltip.remove() and delete @tooltip
    )
    top.push anchor

  drawDot: (x, y, commit) ->
    r = @r
    r.circle(x, y, 3).attr(
      fill: @colors[commit.space]
      stroke: "none"
    )
    r.rect(@offsetX + @unitSpace * @mspace + 10, y - 10, 20, 20).attr(
      fill: "url(#{commit.author.icon})"
      stroke: @colors[commit.space]
      "stroke-width": 2
    )
    r.text(@offsetX + @unitSpace * @mspace + 35, y, commit.message.split("\n")[0]).attr(
      "text-anchor": "start"
      font: "14px Monaco, monospace"
    )

  drawLines: (x, y, commit) ->
    r = @r
    for parent, i in commit.parents
      parentCommit = @preparedCommits[parent[0]]
      parentY = @offsetY + @unitTime * parentCommit.time
      parentX1 = @offsetX + @unitSpace * (@mspace - parentCommit.space)
      parentX2 = @offsetX + @unitSpace * (@mspace - parent[1])

      # Set line color
      if parentCommit.space <= commit.space
        color = @colors[commit.space]

      else
        color = @colors[parentCommit.space]

      # Build line shape
      if parent[1] is commit.space
        d1 = [0, 5]
        d2 = [0, 10]
        arrow = "l-2,5,4,0,-2,-5"

      else if parent[1] < commit.space
        d1 = [3, 3]
        d2 = [7, 5]
        arrow = "l5,0,-2,4,-3,-4"

      else
        d1 = [-3, 3]
        d2 = [-7, 5]
        arrow = "l-5,0,2,4,3,-4"

      # Start point
      route = ["M", x + d1[0], y + d1[1]]

      # Add arrow if not first parent
      if i > 0
        route.push(arrow)

      # Circumvent if overlap
      if commit.space isnt parentCommit.space or commit.space isnt parent[1]
        route.push(
          "L", x + d2[0], y + d2[1],
          "L", parentX2, y + 10,
          "L", parentX2, parentY - 5,
        )

      # End point
      route.push("L", parentX1, parentY)

      r
        .path(route)
        .attr(
          stroke: color
          "stroke-width": 2)

  markCommit: (x, y, commit, graphHeight) ->
    if commit.id is @options.commit_id
      r = @r
      r.path(["M", x + 5, y, "L", x + 15, y + 4, "L", x + 15, y - 4, "Z"]).attr(
        fill: "#000"
        "fill-opacity": .5
        stroke: "none"
      )
      # Displayed in the center
      @element.scrollTop(y - graphHeight / 2)

Raphael::commitTooltip = (x, y, commit) ->
  boxWidth = 300
  boxHeight = 200
  icon = @image(commit.author.icon, x, y, 20, 20)
  nameText = @text(x + 25, y + 10, commit.author.name)
  idText = @text(x, y + 35, commit.id)
  messageText = @text(x, y + 50, commit.message)
  textSet = @set(icon, nameText, idText, messageText).attr(
    "text-anchor": "start"
    font: "12px Monaco, monospace"
  )
  nameText.attr(
    font: "14px Arial"
    "font-weight": "bold"
  )

  idText.attr fill: "#AAA"
  @textWrap messageText, boxWidth - 50
  rect = @rect(x - 10, y - 10, boxWidth, 100, 4).attr(
    fill: "#FFF"
    stroke: "#000"
    "stroke-linecap": "round"
    "stroke-width": 2
  )
  tooltip = @set(rect, textSet)
  rect.attr(
    height: tooltip.getBBox().height + 10
    width: tooltip.getBBox().width + 10
  )

  tooltip.transform ["t", 20, 20]
  tooltip

Raphael::textWrap = (t, width) ->
  content = t.attr("text")
  abc = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  t.attr text: abc
  letterWidth = t.getBBox().width / abc.length
  t.attr text: content
  words = content.split(" ")
  x = 0
  s = []

  for word in words
    if x + (word.length * letterWidth) > width
      s.push "\n"
      x = 0
    x += word.length * letterWidth
    s.push word + " "

  t.attr text: s.join("")
  b = t.getBBox()
  h = Math.abs(b.y2) - Math.abs(b.y) + 1
  t.attr y: b.y + h

@BranchGraph = BranchGraph
