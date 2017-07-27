/* eslint-disable no-var, vars-on-top, eqeqeq, newline-per-chained-call, prefer-arrow-callback, consistent-return, one-var, one-var-declaration-per-line, no-unused-vars, no-else-return, max-len, class-methods-use-this */

import d3 from 'd3';

const LOADING_HTML = `
  <div class="text-center">
    <i class="fa fa-spinner fa-spin user-calendar-activities-loading"></i>
  </div>
`;

export default class ActivityCalendar {
  constructor(timestamps, calendarActivitiesPath) {
    this.calendarActivitiesPath = calendarActivitiesPath;
    this.clickDay = this.clickDay.bind(this);
    this.currentSelectedDate = '';
    this.daySpace = 1;
    this.daySize = 15;
    this.daySizeWithSpace = this.daySize + (this.daySpace * 2);
    this.monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    this.months = [];

    // Loop through the timestamps to create a group of objects
    // The group of objects will be grouped based on the day of the week they are
    this.timestampsTmp = [];
    var group = 0;

    var today = new Date();
    today.setHours(0, 0, 0, 0, 0);

    var oneYearAgo = new Date(today);
    oneYearAgo.setFullYear(today.getFullYear() - 1);

    var days = gl.utils.getDayDifference(oneYearAgo, today);

    for (var i = 0; i <= days; i += 1) {
      var date = new Date(oneYearAgo);
      date.setDate(date.getDate() + i);

      var day = date.getDay();
      var count = timestamps[date.format('yyyy-mm-dd')] || 0;

      // Create a new group array if this is the first day of the week
      // or if is first object
      if ((day === 0 && i !== 0) || i === 0) {
        this.timestampsTmp.push([]);
        group += 1;
      }

      // Push to the inner array the values that will be used to render map
      var innerArray = this.timestampsTmp[group - 1];
      innerArray.push({ count, date, day });
    }

    // Init color functions
    this.colorKey = this.initColorKey();
    this.color = this.initColor();

    // Init the svg element
    this.renderSvg(group);
    this.renderDays();
    this.renderMonths();
    this.renderDayTitles();
    this.renderKey();
    this.initTooltips();
  }

  // Add extra padding for the last month label if it is also the last column
  getExtraWidthPadding(group) {
    var extraWidthPadding = 0;
    var lastColMonth = this.timestampsTmp[group - 1][0].date.getMonth();
    var secondLastColMonth = this.timestampsTmp[group - 2][0].date.getMonth();

    if (lastColMonth != secondLastColMonth) {
      extraWidthPadding = 3;
    }

    return extraWidthPadding;
  }

  renderSvg(group) {
    var width = ((group + 1) * this.daySizeWithSpace) + this.getExtraWidthPadding(group);
    this.svg = d3.select('.js-contrib-calendar').append('svg').attr('width', width).attr('height', 167).attr('class', 'contrib-calendar');
  }

  renderDays() {
    this.svg.selectAll('g').data(this.timestampsTmp).enter().append('g')
      .attr('transform', (group, i) => {
        _.each(group, (stamp, a) => {
          var lastMonth, lastMonthX, month, x;
          if (a === 0 && stamp.day === 0) {
            month = stamp.date.getMonth();
            x = (this.daySizeWithSpace * i) + 1 + this.daySizeWithSpace;
            lastMonth = _.last(this.months);
            if (lastMonth != null) {
              lastMonthX = lastMonth.x;
            }
            if (lastMonth == null) {
              return this.months.push({ month, x });
            } else if (month !== lastMonth.month && x - this.daySizeWithSpace !== lastMonthX) {
              return this.months.push({ month, x });
            }
          }
        });
        return `translate(${(this.daySizeWithSpace * i) + 1 + this.daySizeWithSpace}, 18)`;
      })
      .selectAll('rect')
      .data(stamp => stamp)
      .enter()
      .append('rect')
      .attr('x', '0')
      .attr('y', stamp => this.daySizeWithSpace * stamp.day)
      .attr('width', this.daySize)
      .attr('height', this.daySize)
      .attr('title', (stamp) => {
        var contribText, date, dateText;
        date = new Date(stamp.date);
        contribText = 'No contributions';
        if (stamp.count > 0) {
          contribText = `${stamp.count} contribution${stamp.count > 1 ? 's' : ''}`;
        }
        dateText = date.format('mmm d, yyyy');
        return `${contribText}<br />${gl.utils.getDayName(date)} ${dateText}`;
      })
      .attr('class', 'user-contrib-cell js-tooltip').attr('fill', (stamp) => {
        if (stamp.count !== 0) {
          return this.color(Math.min(stamp.count, 40));
        } else {
          return '#ededed';
        }
      })
      .attr('data-container', 'body')
      .on('click', this.clickDay);
  }

  renderDayTitles() {
    const days = [
      {
        text: 'M',
        y: 29 + (this.daySizeWithSpace * 1),
      }, {
        text: 'W',
        y: 29 + (this.daySizeWithSpace * 3),
      }, {
        text: 'F',
        y: 29 + (this.daySizeWithSpace * 5),
      },
    ];
    this.svg.append('g')
      .selectAll('text')
        .data(days)
        .enter()
        .append('text')
          .attr('text-anchor', 'middle')
          .attr('x', 8)
          .attr('y', day => day.y)
          .text(day => day.text)
          .attr('class', 'user-contrib-text');
  }

  renderMonths() {
    this.svg.append('g')
      .attr('direction', 'ltr')
      .selectAll('text')
        .data(this.months)
        .enter()
        .append('text')
          .attr('x', date => date.x)
          .attr('y', 10)
          .attr('class', 'user-contrib-text')
          .text(date => this.monthNames[date.month]);
  }

  renderKey() {
    const keyValues = ['no contributions', '1-9 contributions', '10-19 contributions', '20-29 contributions', '30+ contributions'];
    const keyColors = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];

    this.svg.append('g')
      .attr('transform', `translate(18, ${(this.daySizeWithSpace * 8) + 16})`)
      .selectAll('rect')
        .data(keyColors)
        .enter()
        .append('rect')
          .attr('width', this.daySize)
          .attr('height', this.daySize)
          .attr('x', (color, i) => this.daySizeWithSpace * i)
          .attr('y', 0)
          .attr('fill', color => color)
          .attr('class', 'js-tooltip')
          .attr('title', (color, i) => keyValues[i])
          .attr('data-container', 'body');
  }

  initColor() {
    var colorRange;
    colorRange = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];
    return d3.scale.threshold().domain([0, 10, 20, 30]).range(colorRange);
  }

  initColorKey() {
    return d3.scale.linear().range(['#acd5f2', '#254e77']).domain([0, 3]);
  }

  clickDay(stamp) {
    if (this.currentSelectedDate !== stamp.date) {
      this.currentSelectedDate = stamp.date;

      const date = [
        this.currentSelectedDate.getFullYear(),
        this.currentSelectedDate.getMonth() + 1,
        this.currentSelectedDate.getDate(),
      ].join('-');

      $.ajax({
        url: this.calendarActivitiesPath,
        data: { date },
        cache: false,
        dataType: 'html',
        beforeSend: () => $('.user-calendar-activities').html(LOADING_HTML),
        success: data => $('.user-calendar-activities').html(data),
      });
    } else {
      this.currentSelectedDate = '';
      $('.user-calendar-activities').html('');
    }
  }

  initTooltips() {
    $('.js-contrib-calendar .js-tooltip').tooltip({ html: true });
  }
}
