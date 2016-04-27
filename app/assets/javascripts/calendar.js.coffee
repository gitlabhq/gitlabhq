class @Calendar
  constructor: (timestamps, calendar_activities_path) ->
    # Get the highest value from the timestampes
    highestValue = 0
    _.each timestamps, (count) ->
      if count > highestValue
        highestValue = count

    # Loop through the timestamps to create a group of objects
    # The group of objects will be grouped based on the day of the week they are
    timestampsTmp = []
    i = 0
    group = 0
    _.each timestamps, (count, date) ->
      newDate = new Date parseInt(date) * 1000
      day = newDate.getDay()

      # Create a new group array if this is the first day of the week
      # or if is first object
      if (day is 0 and i isnt 0) or i is 0
        timestampsTmp.push []
        group++

      innerArray = timestampsTmp[group-1]

      # Push to the inner array the values that will be used to render map
      innerArray.push
        count: count
        date: newDate
        day: day

      i++

    # Color function for chart
    color = d3
      .scale
      .linear()
      .range(['#acd5f2', '#254e77'])
      .domain([0, highestValue])

    # Color function for key
    colorKey = d3
      .scale
      .linear()
      .range(['#acd5f2', '#254e77'])
      .domain([0, 3])
    keyColors = ['#ededed', colorKey(0), colorKey(1), colorKey(2), colorKey(3)]

    monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    months = []
    svg = d3.select '.js-contrib-calendar'
      .append 'svg'
      .attr 'width', 54 * 17
      .attr 'height', 167
      .attr 'class', 'contrib-calendar'

    # Setup each day box
    svg.selectAll 'g'
      .data timestampsTmp
      .enter()
      .append 'g'
      .attr 'transform', (group, i) ->
        _.each group, (stamp, a) ->
          if a is 0 and stamp.day is 0
            month = stamp.date.getMonth()
            x = (17 * i + 1) + 17
            lastMonth = _.last(months)
            if lastMonth?
              lastMonthX = lastMonth.x

            if !lastMonth?
              months.push
                month: month
                x: x
            else if month isnt lastMonth.month and x - 17 isnt lastMonthX
              months.push
                month: month
                x: x

        "translate(#{(17 * i + 1) + 17}, 18)"
      .selectAll 'rect'
      .data (stamp) ->
        stamp
      .enter()
      .append 'rect'
      .attr 'x', '0'
      .attr 'y', (stamp, i) ->
        (17 * stamp.day)
      .attr 'width', 15
      .attr 'height', 15
      .attr 'title', (stamp) ->
        "#{stamp.count} contributions<br />#{gl.utils.formatDate stamp.date}"
      .attr 'class', 'user-contrib-cell js-tooltip'
      .attr 'fill', (stamp) ->
        if stamp.count isnt 0
          color(stamp.count)
        else
          '#ededed'
      .attr 'data-container', 'body'
      .on 'click', (stamp) ->
        date = stamp.date
        formated_date = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + date.getDate()
        $.ajax
          url: calendar_activities_path
          data:
            date: formated_date
          cache: false
          dataType: "html"
          success: (data) ->
            $(".user-calendar-activities").html data

    # Month titles
    svg.append 'g'
      .selectAll 'text'
      .data months
      .enter()
      .append 'text'
      .attr 'x', (date) ->
        date.x
      .attr 'y', 10
      .attr 'class', 'user-contrib-text'
      .text (date) ->
        monthNames[date.month]

    # Day titles
    days = [{
      text: 'M'
      y: 29 + (17 * 1)
    }, {
      text: 'W'
      y: 29 + (17 * 3)
    }, {
      text: 'F'
      y: 29 + (17 * 5)
    }]
    svg.append 'g'
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

    # Key with color boxes
    svg.append 'g'
      .attr 'transform', "translate(18, #{17 * 8 + 16})"
      .selectAll 'rect'
      .data keyColors
      .enter()
      .append 'rect'
      .attr 'width', 15
      .attr 'height', 15
      .attr 'x', (color, i) ->
        17 * i
      .attr 'y', 0
      .attr 'fill', (color) ->
        color

    $('.js-contrib-calendar .js-tooltip').tooltip
      html: true
