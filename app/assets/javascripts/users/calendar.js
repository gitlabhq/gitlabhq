var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

this.Calendar = (function() {
  function Calendar(timestamps, calendar_activities_path) {
    var group, i;
    this.calendar_activities_path = calendar_activities_path;
    this.clickDay = bind(this.clickDay, this);
    this.currentSelectedDate = '';
    this.daySpace = 1;
    this.daySize = 15;
    this.daySizeWithSpace = this.daySize + (this.daySpace * 2);
    this.monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    this.months = [];
    this.timestampsTmp = [];
    i = 0;
    group = 0;
    _.each(timestamps, (function(_this) {
      return function(count, date) {
        var day, innerArray, newDate;
        newDate = new Date(parseInt(date) * 1000);
        day = newDate.getDay();
        if ((day === 0 && i !== 0) || i === 0) {
          _this.timestampsTmp.push([]);
          group++;
        }
        innerArray = _this.timestampsTmp[group - 1];
        innerArray.push({
          count: count,
          date: newDate,
          day: day
        });
        return i++;
      };
    })(this));
    this.colorKey = this.initColorKey();
    this.color = this.initColor();
    this.renderSvg(group);
    this.renderDays();
    this.renderMonths();
    this.renderDayTitles();
    this.renderKey();
    this.initTooltips();
  }

  Calendar.prototype.renderSvg = function(group) {
    return this.svg = d3.select('.js-contrib-calendar').append('svg').attr('width', (group + 1) * this.daySizeWithSpace).attr('height', 167).attr('class', 'contrib-calendar');
  };

  Calendar.prototype.renderDays = function() {
    return this.svg.selectAll('g').data(this.timestampsTmp).enter().append('g').attr('transform', (function(_this) {
      return function(group, i) {
        _.each(group, function(stamp, a) {
          var lastMonth, lastMonthX, month, x;
          if (a === 0 && stamp.day === 0) {
            month = stamp.date.getMonth();
            x = (_this.daySizeWithSpace * i + 1) + _this.daySizeWithSpace;
            lastMonth = _.last(_this.months);
            if (lastMonth != null) {
              lastMonthX = lastMonth.x;
            }
            if (lastMonth == null) {
              return _this.months.push({
                month: month,
                x: x
              });
            } else if (month !== lastMonth.month && x - _this.daySizeWithSpace !== lastMonthX) {
              return _this.months.push({
                month: month,
                x: x
              });
            }
          }
        });
        return "translate(" + ((_this.daySizeWithSpace * i + 1) + _this.daySizeWithSpace) + ", 18)";
      };
    })(this)).selectAll('rect').data(function(stamp) {
      return stamp;
    }).enter().append('rect').attr('x', '0').attr('y', (function(_this) {
      return function(stamp, i) {
        return _this.daySizeWithSpace * stamp.day;
      };
    })(this)).attr('width', this.daySize).attr('height', this.daySize).attr('title', (function(_this) {
      return function(stamp) {
        var contribText, date, dateText;
        date = new Date(stamp.date);
        contribText = 'No contributions';
        if (stamp.count > 0) {
          contribText = stamp.count + " contribution" + (stamp.count > 1 ? 's' : '');
        }
        dateText = dateFormat(date, 'mmm d, yyyy');
        return contribText + "<br />" + (gl.utils.getDayName(date)) + " " + dateText;
      };
    })(this)).attr('class', 'user-contrib-cell js-tooltip').attr('fill', (function(_this) {
      return function(stamp) {
        if (stamp.count !== 0) {
          return _this.color(Math.min(stamp.count, 40));
        } else {
          return '#ededed';
        }
      };
    })(this)).attr('data-container', 'body').on('click', this.clickDay);
  };

  Calendar.prototype.renderDayTitles = function() {
    var days;
    days = [
      {
        text: 'M',
        y: 29 + (this.daySizeWithSpace * 1)
      }, {
        text: 'W',
        y: 29 + (this.daySizeWithSpace * 3)
      }, {
        text: 'F',
        y: 29 + (this.daySizeWithSpace * 5)
      }
    ];
    return this.svg.append('g').selectAll('text').data(days).enter().append('text').attr('text-anchor', 'middle').attr('x', 8).attr('y', function(day) {
      return day.y;
    }).text(function(day) {
      return day.text;
    }).attr('class', 'user-contrib-text');
  };

  Calendar.prototype.renderMonths = function() {
    return this.svg.append('g').selectAll('text').data(this.months).enter().append('text').attr('x', function(date) {
      return date.x;
    }).attr('y', 10).attr('class', 'user-contrib-text').text((function(_this) {
      return function(date) {
        return _this.monthNames[date.month];
      };
    })(this));
  };

  Calendar.prototype.renderKey = function() {
    var keyColors;
    keyColors = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];
    return this.svg.append('g').attr('transform', "translate(18, " + (this.daySizeWithSpace * 8 + 16) + ")").selectAll('rect').data(keyColors).enter().append('rect').attr('width', this.daySize).attr('height', this.daySize).attr('x', (function(_this) {
      return function(color, i) {
        return _this.daySizeWithSpace * i;
      };
    })(this)).attr('y', 0).attr('fill', function(color) {
      return color;
    });
  };

  Calendar.prototype.initColor = function() {
    var colorRange;
    colorRange = ['#ededed', this.colorKey(0), this.colorKey(1), this.colorKey(2), this.colorKey(3)];
    return d3.scale.threshold().domain([0, 10, 20, 30]).range(colorRange);
  };

  Calendar.prototype.initColorKey = function() {
    return d3.scale.linear().range(['#acd5f2', '#254e77']).domain([0, 3]);
  };

  Calendar.prototype.clickDay = function(stamp) {
    var formatted_date;
    if (this.currentSelectedDate !== stamp.date) {
      this.currentSelectedDate = stamp.date;
      formatted_date = this.currentSelectedDate.getFullYear() + "-" + (this.currentSelectedDate.getMonth() + 1) + "-" + this.currentSelectedDate.getDate();
      return $.ajax({
        url: this.calendar_activities_path,
        data: {
          date: formatted_date
        },
        cache: false,
        dataType: 'html',
        beforeSend: function() {
          return $('.user-calendar-activities').html('<div class="text-center"><i class="fa fa-spinner fa-spin user-calendar-activities-loading"></i></div>');
        },
        success: function(data) {
          return $('.user-calendar-activities').html(data);
        }
      });
    } else {
      return $('.user-calendar-activities').html('');
    }
  };

  Calendar.prototype.initTooltips = function() {
    return $('.js-contrib-calendar .js-tooltip').tooltip({
      html: true
    });
  };

  return Calendar;

})();
