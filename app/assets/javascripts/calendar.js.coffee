class @Calendar
  constructor: (timestamps, starting_year, starting_month, calendar_activities_path) ->
    # Get the highest value from the timestampes
    highestValue = 0
    _.each timestamps, (count) ->
      if count > highestValue
        highestValue = count

    timestamps = _.chain(timestamps)
      .map (stamp, key) ->
        {
          count: stamp
          date: key
        }
      .groupBy (stamp, i) ->
        Math.floor i / 7
      .toArray()
      .value()

    monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    months = []
    svg = d3.select '#cal-heatmap'
      .append 'svg'
      .attr 'width', 53 * 17
      .attr 'height', 140

    # Setup each day box
    svg.selectAll 'g'
      .data timestamps
      .enter()
      .append 'g'
      .attr 'transform', (group, i) ->
        _.each group, (stamp) ->
          month = new Date(parseInt(stamp.date) * 1000).getMonth()
          x = 17 * i + 1
          lastMonth = _.last(months)

          # If undefined, push
          if !lastMonth?
            months.push
              month: month
              x: x
          else if lastMonth.x is x
            lastMonth.month = month
          else if lastMonth.month isnt month
              months.push
                month: month
                x: x
        "translate(#{17 * i + 1}, 18)"
      .selectAll 'rect'
      .data (stamp) ->
        stamp
      .enter()
      .append 'rect'
      .attr 'x', '0'
      .attr 'y', (stamp, i) ->
        17 * i
      .attr 'width', 15
      .attr 'height', 15
      .attr 'title', (stamp) ->
        "#{stamp.count} contributions<br />#{gl.utils.formatDate parseInt(stamp.date) * 1000}"
      .attr 'class', (stamp) ->
        extraClass = ''
        if stamp.count isnt 0
          diff = stamp.count / highestValue
          classNumber = Math.floor (diff / 0.25) + 1
          extraClass += "user-contrib-cell-#{classNumber}"

        "user-contrib-cell #{extraClass} js-tooltip"
      .attr 'data-container', 'body'
      .on 'click', (stamp) ->
        date = new Date(parseInt(stamp.date) * 1000)
        formated_date = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + date.getDate()
        $.ajax
          url: calendar_activities_path
          data:
            date: formated_date
          cache: false
          dataType: "html"
          success: (data) ->
            $(".user-calendar-activities").html data

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

    $('#cal-heatmap .js-tooltip').tooltip
      html: true
