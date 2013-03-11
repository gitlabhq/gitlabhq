class BranchGraph
  constructor: (@element, @options) ->
    @preparedCommits = {}
    @mtime = 0
    @mspace = 0
    @parents = {}
    @colors = ["#000"]
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
    @mtime += 4
    @mspace += 10

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

  collectColors: ->
    k = 0
    while k < @mspace
      @colors.push Raphael.getColor(.8)
      # Skipping a few colors in the spectrum to get more contrast between colors
      Raphael.getColor()
      Raphael.getColor()
      k++

  buildGraph: ->
    graphWidth = $(@element).width()
    ch = @mspace * 20 + 100
    cw = Math.max(graphWidth, @mtime * 20 + 260)
    r = Raphael(@element.get(0), cw, ch)
    top = r.set()
    cuday = 0
    cumonth = ""
    offsetX = 20
    offsetY = 60
    barWidth = Math.max(graphWidth, @days.length * 20 + 320)
    scrollLeft = cw
    @raphael = r
    r.rect(0, 0, barWidth, 20).attr fill: "#222"
    r.rect(0, 20, barWidth, 20).attr fill: "#444"

    for day, mm in @days
      if cuday isnt day[0]
        # Dates
        r.text(offsetX + mm * 20, 31, day[0])
          .attr(
            font: "12px Monaco, monospace"
            fill: "#DDD"
          )
        cuday = day[0]

      if cumonth isnt day[1]
        # Months
        r.text(offsetX + mm * 20, 11, day[1])
          .attr(
            font: "12px Monaco, monospace"
            fill: "#EEE"
          )
        cumonth = day[1]

    for commit in @commits
      x = offsetX + 20 * commit.time
      y = offsetY + 10 * commit.space
      # Draw dot
      r.circle(x, y, 3).attr(
        fill: @colors[commit.space]
        stroke: "none"
      )

      # Draw lines
      for parent in commit.parents
        parentCommit = @preparedCommits[parent[0]]
        parentX = offsetX + 20 * parentCommit.time
        parentY1 = offsetY + 10 * parentCommit.space
        parentY2 = offsetY + 10 * parent[1]
        if parentCommit.space is commit.space and parentCommit.space is parent[1]
          r.path(["M", x, y, "L", parentX, parentY1]).attr(
            stroke: @colors[parentCommit.space]
            "stroke-width": 2
          )

        else if parentCommit.space < commit.space
          if y is parentY2
            r.path(["M", x - 5, y, "l-5,-2,0,4,5,-2", "L", x - 10, y, "L", x - 15, parentY2, "L", parentX + 5, parentY2, "L", parentX, parentY1]).attr(
              stroke: @colors[commit.space]
              "stroke-width": 2
            )

          else
            r.path(["M", x - 3, y - 6, "l-4,-3,4,-2,0,5", "L", x - 5, y - 10, "L", x - 10, parentY2, "L", parentX + 5, parentY2, "L", parentX, parentY1]).attr(
              stroke: @colors[commit.space]
              "stroke-width": 2
            )

        else
          r.path(["M", x - 3, y + 6, "l-4,3,4,2,0,-5", "L", x - 5, y + 10, "L", x - 10, parentY2, "L", parentX + 5, parentY2, "L", parentX, parentY1]).attr(
            stroke: @colors[parentCommit.space]
            "stroke-width": 2
          )

      @appendLabel x, y, commit.refs  if commit.refs

      # Mark commit and displayed in the center
      if commit.id is @options.commit_id
        r.path(["M", x, y - 5, "L", x + 4, y - 15, "L", x - 4, y - 15, "Z"]).attr(
          fill: "#000"
          "fill-opacity": .7
          stroke: "none"
        )

        scrollLeft = x - graphWidth / 2

      @appendAnchor top, commit, x, y

    top.toFront()
    @element.scrollLeft scrollLeft
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
    r = @raphael
    shortrefs = refs
    # Truncate if longer than 15 chars
    shortrefs = shortrefs.substr(0, 15) + "…"  if shortrefs.length > 17
    text = r.text(x + 5, y + 8 + 10, shortrefs).attr(
      font: "10px Monaco, monospace"
      fill: "#FFF"
      title: refs
    )
    textbox = text.getBBox()
    text.transform ["t", textbox.height / -4, textbox.width / 2 + 5, "r90"]
    # Create rectangle based on the size of the textbox
    rect = r.rect(x, y, textbox.width + 15, textbox.height + 5, 4).attr(
      fill: "#000"
      "fill-opacity": .7
      stroke: "none"
    )
    triangle = r.path(["M", x, y + 5, "L", x + 4, y + 15, "L", x - 4, y + 15, "Z"]).attr(
      fill: "#000"
      "fill-opacity": .7
      stroke: "none"
    )
    # Rotate and reposition rectangle over text
    rect.transform ["r", 90, x, y, "t", 15, -9]
    # Set text to front
    text.toFront()

  appendAnchor: (top, commit, x, y) ->
    r = @raphael
    options = @options
    anchor = r.circle(x, y, 10).attr(
      fill: "#000"
      opacity: 0
      cursor: "pointer"
    ).click(->
      window.open options.commit_url.replace("%s", commit.id), "_blank"
    ).hover(->
      @tooltip = r.commitTooltip(x, y + 5, commit)
      top.push @tooltip.insertBefore(this)
    , ->
      @tooltip and @tooltip.remove() and delete @tooltip
    )
    top.push anchor

Raphael::commitTooltip = (x, y, commit) ->
  icon = undefined
  nameText = undefined
  idText = undefined
  messageText = undefined
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
