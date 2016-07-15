class @Calendar
  constructor: (timestamps, @calendar_activities_path) ->
    @currentSelectedDate = ''
    @daySpace = 1
    @daySize = 15
    @daySizeWithSpace = @daySize + (@daySpace * 2)
    @monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    @months = []

    # Loop through the timestamps to create a group of objects
    # The group of objects will be grouped based on the day of the week they are
    @timestampsTmp = []
    i = 0
    group = 0
    _.each timestamps, (count, date) =>
      newDate = new Date parseInt(date) * 1000
      day = newDate.getDay()

      # Create a new group array if this is the first day of the week
      # or if is first object
      if (day is 0 and i isnt 0) or i is 0
        @timestampsTmp.push []
        group++

      innerArray = @timestampsTmp[group-1]

      # Push to the inner array the values that will be used to render map
      innerArray.push
        count: count
        date: newDate
        day: day

      i++

    # Init color functions
    @colorKey = @initColorKey()
    @color = @initColor()

    # Init the svg element
    @renderSvg(group)
    @renderDays()
    @renderMonths()
    @renderDayTitles()
    @renderKey()

    @initTooltips()

  renderSvg: (group) ->
    @svg = d3.select '.js-contrib-calendar'
      .append 'svg'
      .attr 'width', (group + 1) * @daySizeWithSpace
      .attr 'height', 167
      .attr 'class', 'contrib-calendar'

  renderDays: ->
    @svg.selectAll 'g'
      .data @timestampsTmp
      .enter()
      .append 'g'
      .attr 'transform', (group, i) =>
        _.each group, (stamp, a) =>
          if a is 0 and stamp.day is 0
            month = stamp.date.getMonth()
            x = (@daySizeWithSpace * i + 1) + @daySizeWithSpace
            lastMonth = _.last(@months)
            if lastMonth?
              lastMonthX = lastMonth.x

            if !lastMonth?
              @months.push
                month: month
                x: x
            else if month isnt lastMonth.month and x - @daySizeWithSpace isnt lastMonthX
              @months.push
                month: month
                x: x

        "translate(#{(@daySizeWithSpace * i + 1) + @daySizeWithSpace}, 18)"
      .selectAll 'rect'
      .data (stamp) ->
        stamp
      .enter()
      .append 'rect'
      .attr 'x', '0'
      .attr 'y', (stamp, i) =>
        (@daySizeWithSpace * stamp.day)
      .attr 'width', @daySize
      .attr 'height', @daySize
      .attr 'title', (stamp) =>
        date = new Date(stamp.date)
        contribText = 'No contributions'

        if stamp.count > 0
          contribText = "#{stamp.count} contribution#{if stamp.count > 1 then 's' else ''}"

        dateText = dateFormat(date, 'mmm d, yyyy')

        "#{contribText}<br />#{gl.utils.getDayName(date)} #{dateText}"
      .attr 'class', 'user-contrib-cell js-tooltip'
      .attr 'fill', (stamp) =>
        if stamp.count isnt 0
          @color(Math.min(stamp.count, 40))
        else
          '#ededed'
      .attr 'data-container', 'body'
      .on 'click', @clickDay

  renderDayTitles: ->
    days = [{
      text: 'M'
      y: 29 + (@daySizeWithSpace * 1)
    }, {
      text: 'W'
      y: 29 + (@daySizeWithSpace * 3)
    }, {
      text: 'F'
      y: 29 + (@daySizeWithSpace * 5)
    }]
    @svg.append 'g'
      .selectAll 'text'
      .data days
      .enter()
      .append 'text'
      .attr 'text-anchor', 'middle'
      .attr 'x', 8
      .attr 'y', (day) ->
        day.y
      .text (day) ->
        day.text
      .attr 'class', 'user-contrib-text'

  renderMonths: ->
    @svg.append 'g'
      .selectAll 'text'
      .data @months
      .enter()
      .append 'text'
      .attr 'x', (date) ->
        date.x
      .attr 'y', 10
      .attr 'class', 'user-contrib-text'
      .text (date) =>
        @monthNames[date.month]

  renderKey: ->
    keyColors = ['#ededed', @colorKey(0), @colorKey(1), @colorKey(2), @colorKey(3)]
    @svg.append 'g'
      .attr 'transform', "translate(18, #{@daySizeWithSpace * 8 + 16})"
      .selectAll 'rect'
      .data keyColors
      .enter()
      .append 'rect'
      .attr 'width', @daySize
      .attr 'height', @daySize
      .attr 'x', (color, i) =>
        @daySizeWithSpace * i
      .attr 'y', 0
      .attr 'fill', (color) ->
        color

  initColor: ->
    colorRange = ['#ededed', @colorKey(0), @colorKey(1), @colorKey(2), @colorKey(3)]
    d3.scale
      .threshold()
      .domain([0, 10, 20, 30])
      .range(colorRange)

  initColorKey: ->
    d3.scale
      .linear()
      .range(['#acd5f2', '#254e77'])
      .domain([0, 3])

  clickDay: (stamp) =>
    if @currentSelectedDate isnt stamp.date
      @currentSelectedDate = stamp.date
      formatted_date = @currentSelectedDate.getFullYear() + "-" + (@currentSelectedDate.getMonth()+1) + "-" + @currentSelectedDate.getDate()

      $.ajax
        url: @calendar_activities_path
        data:
          date: formatted_date
        cache: false
        dataType: 'html'
        beforeSend: ->
          $('.user-calendar-activities').html '<div class="text-center"><i class="fa fa-spinner fa-spin user-calendar-activities-loading"></i></div>'
        success: (data) ->
          $('.user-calendar-activities').html data
    else
      $('.user-calendar-activities').html ''

  initTooltips: ->
    $('.js-contrib-calendar .js-tooltip').tooltip
      html: true
