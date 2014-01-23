class window.ContributorsGraph
  MARGIN:
    top: 20
    right: 20
    bottom: 30
    left: 50
  x_domain: null
  y_domain: null
  dates: []
  @set_x_domain: (data) =>
    @prototype.x_domain = data
  @set_y_domain: (data) =>
    @prototype.y_domain = [0, d3.max(data, (d) ->
      d.commits = d.commits ? d.additions ? d.deletions
    )]
  @init_x_domain: (data) =>
    @prototype.x_domain = d3.extent(data, (d) ->
     d.date
    )
  @init_y_domain: (data) =>
    @prototype.y_domain = [0, d3.max(data, (d) ->
      d.commits = d.commits ? d.additions ? d.deletions
    )]
  @init_domain: (data) =>
    @init_x_domain(data)
    @init_y_domain(data)
  @set_dates: (data) =>
    @prototype.dates = data
  set_x_domain: ->
    @x.domain(@x_domain)
  set_y_domain: ->
    @y.domain(@y_domain)
  set_domain: ->
    @set_x_domain()
    @set_y_domain()
  create_scale: (width, height) ->
    @x = d3.time.scale().range([0, width]).clamp(true)
    @y = d3.scale.linear().range([height, 0]).nice()
  draw_x_axis: ->
    @svg.append("g").attr("class", "x axis").attr("transform", "translate(0, #{@height})")
    .call(@x_axis)
  draw_y_axis: ->
    @svg.append("g").attr("class", "y axis").call(@y_axis)
  set_data: (data) ->
    @data = data

class window.ContributorsMasterGraph extends ContributorsGraph
  constructor: (@data) ->
    @width = $('.container').width() - 70
    @height = 200
    @x = null
    @y = null
    @x_axis = null
    @y_axis = null
    @area = null
    @svg = null
    @brush = null
    @x_max_domain = null
  process_dates: (data) ->
    dates = @get_dates(data)
    @parse_dates(data)
    ContributorsGraph.set_dates(dates)
  get_dates: (data) ->
    _.pluck(data, 'date')
  parse_dates: (data) ->
    parseDate = d3.time.format("%Y-%m-%d").parse
    data.forEach((d) ->
      d.date = parseDate(d.date)
    )
  create_scale: ->
    super @width, @height
  create_axes: ->
    @x_axis = d3.svg.axis().scale(@x).orient("bottom")
    @y_axis = d3.svg.axis().scale(@y).orient("left").ticks(5)
  create_svg: ->
    @svg = d3.select("#contributors-master").append("svg")
    .attr("width", @width + @MARGIN.left + @MARGIN.right)
    .attr("height", @height + @MARGIN.top + @MARGIN.bottom)
    .attr("class", "tint-box")
    .append("g")
    .attr("transform", "translate(" + @MARGIN.left + "," + @MARGIN.top + ")")
  create_area: (x, y) ->
    @area = d3.svg.area().x((d) ->
      x(d.date)
    ).y0(@height).y1((d) ->
      xa = d.commits = d.commits ? d.additions ? d.deletions
      y(xa)
    ).interpolate("basis")
  create_brush: ->
    @brush = d3.svg.brush().x(@x).on("brushend", @update_content)
  draw_path: (data) ->
    @svg.append("path").datum(data).attr("class", "area").attr("d", @area)
  add_brush: ->
    @svg.append("g").attr("class", "selection").call(@brush).selectAll("rect").attr("height", @height)
  update_content: =>
    ContributorsGraph.set_x_domain(if @brush.empty() then @x_max_domain else @brush.extent())
    $("#brush_change").trigger('change')
  draw: ->
    @process_dates(@data)
    @create_scale()
    @create_axes()
    ContributorsGraph.init_domain(@data)
    @x_max_domain = @x_domain
    @set_domain()
    @create_area(@x, @y)
    @create_svg()
    @create_brush()
    @draw_path(@data)
    @draw_x_axis()
    @draw_y_axis()
    @add_brush()
  redraw: ->
    @process_dates(@data)
    ContributorsGraph.set_y_domain(@data)
    @set_y_domain()
    @svg.select("path").datum(@data)
    @svg.select("path").attr("d", @area)
    @svg.select(".y.axis").call(@y_axis)

class window.ContributorsAuthorGraph extends ContributorsGraph
  constructor: (@data) ->
    @width = $('.container').width()/2 - 100
    @height = 200
    @x = null
    @y = null
    @x_axis = null
    @y_axis = null
    @area = null
    @svg = null
    @list_item = null
  create_scale: ->
    super @width, @height
  create_axes: ->
    @x_axis = d3.svg.axis().scale(@x).orient("bottom").ticks(8)
    @y_axis = d3.svg.axis().scale(@y).orient("left").ticks(5)
  create_area: (x, y) ->
    @area = d3.svg.area().x((d) ->
      parseDate = d3.time.format("%Y-%m-%d").parse
      x(parseDate(d))
    ).y0(@height).y1((d) =>
      if @data[d]? then y(@data[d]) else y(0)
    ).interpolate("basis")
  create_svg: ->
    @list_item = d3.selectAll(".person")[0].pop()
    @svg = d3.select(@list_item).append("svg")
    .attr("width", @width + @MARGIN.left + @MARGIN.right)
    .attr("height", @height + @MARGIN.top + @MARGIN.bottom)
    .attr("class", "spark")
    .append("g")
    .attr("transform", "translate(" + @MARGIN.left + "," + @MARGIN.top + ")")
  draw_path: (data) ->
    @svg.append("path").datum(data).attr("class", "area-contributor").attr("d", @area)
  draw: ->
    @create_scale()
    @create_axes()
    @set_domain()
    @create_area(@x, @y)
    @create_svg()
    @draw_path(@dates)
    @draw_x_axis()
    @draw_y_axis()
  redraw: ->
    @set_domain()
    @svg.select("path").datum(@dates)
    @svg.select("path").attr("d", @area)
    @svg.select(".x.axis").call(@x_axis)
    @svg.select(".y.axis").call(@y_axis)
