/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, max-len, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, comma-dangle, no-return-assign, prefer-arrow-callback, quotes, prefer-template, newline-per-chained-call, no-else-return, no-shadow */

import $ from 'jquery';
import _ from 'underscore';
import { extent, max } from 'd3-array';
import { select, event as d3Event } from 'd3-selection';
import { scaleTime, scaleLinear } from 'd3-scale';
import { axisLeft, axisBottom } from 'd3-axis';
import { area } from 'd3-shape';
import { brushX } from 'd3-brush';
import { timeParse } from 'd3-time-format';
import { dateTickFormat } from '~/lib/utils/tick_formats';

const d3 = { extent, max, select, scaleTime, scaleLinear, axisLeft, axisBottom, area, brushX, timeParse };

const extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
const hasProp = {}.hasOwnProperty;

export const ContributorsGraph = (function() {
  function ContributorsGraph() {}

  ContributorsGraph.prototype.MARGIN = {
    top: 20,
    right: 20,
    bottom: 30,
    left: 50
  };

  ContributorsGraph.prototype.x_domain = null;

  ContributorsGraph.prototype.y_domain = null;

  ContributorsGraph.prototype.dates = [];

  ContributorsGraph.set_x_domain = function(data) {
    return ContributorsGraph.prototype.x_domain = data;
  };

  ContributorsGraph.set_y_domain = function(data) {
    return ContributorsGraph.prototype.y_domain = [
      0, d3.max(data, function(d) {
        return d.commits = d.commits || d.additions || d.deletions;
      })
    ];
  };

  ContributorsGraph.init_x_domain = function(data) {
    return ContributorsGraph.prototype.x_domain = d3.extent(data, function(d) {
      return d.date;
    });
  };

  ContributorsGraph.init_y_domain = function(data) {
    return ContributorsGraph.prototype.y_domain = [
      0, d3.max(data, function(d) {
        return d.commits = d.commits || d.additions || d.deletions;
      })
    ];
  };

  ContributorsGraph.init_domain = function(data) {
    ContributorsGraph.init_x_domain(data);
    return ContributorsGraph.init_y_domain(data);
  };

  ContributorsGraph.set_dates = function(data) {
    return ContributorsGraph.prototype.dates = data;
  };

  ContributorsGraph.prototype.set_x_domain = function() {
    return this.x.domain(this.x_domain);
  };

  ContributorsGraph.prototype.set_y_domain = function() {
    return this.y.domain(this.y_domain);
  };

  ContributorsGraph.prototype.set_domain = function() {
    this.set_x_domain();
    return this.set_y_domain();
  };

  ContributorsGraph.prototype.create_scale = function(width, height) {
    this.x = d3.scaleTime().range([0, width]).clamp(true);
    return this.y = d3.scaleLinear().range([height, 0]).nice();
  };

  ContributorsGraph.prototype.draw_x_axis = function() {
    return this.svg.append("g").attr("class", "x axis").attr("transform", "translate(0, " + this.height + ")").call(this.x_axis);
  };

  ContributorsGraph.prototype.draw_y_axis = function() {
    return this.svg.append("g").attr("class", "y axis").call(this.y_axis);
  };

  ContributorsGraph.prototype.set_data = function(data) {
    return this.data = data;
  };

  return ContributorsGraph;
})();

export const ContributorsMasterGraph = (function(superClass) {
  extend(ContributorsMasterGraph, superClass);

  function ContributorsMasterGraph(data1) {
    const $parentElement = $('#contributors-master');
    const parentPadding = parseFloat($parentElement.css('padding-left')) + parseFloat($parentElement.css('padding-right'));

    this.data = data1;
    this.update_content = this.update_content.bind(this);
    this.width = $('.content').width() - parentPadding - (this.MARGIN.left + this.MARGIN.right);
    this.height = 200;
    this.x = null;
    this.y = null;
    this.x_axis = null;
    this.y_axis = null;
    this.area = null;
    this.svg = null;
    this.brush = null;
    this.x_max_domain = null;
  }

  ContributorsMasterGraph.prototype.process_dates = function(data) {
    var dates;
    dates = this.get_dates(data);
    this.parse_dates(data);
    return ContributorsGraph.set_dates(dates);
  };

  ContributorsMasterGraph.prototype.get_dates = function(data) {
    return _.pluck(data, 'date');
  };

  ContributorsMasterGraph.prototype.parse_dates = function(data) {
    var parseDate;
    parseDate = d3.timeParse("%Y-%m-%d");
    return data.forEach(function(d) {
      return d.date = parseDate(d.date);
    });
  };

  ContributorsMasterGraph.prototype.create_scale = function() {
    return ContributorsMasterGraph.__super__.create_scale.call(this, this.width, this.height);
  };

  ContributorsMasterGraph.prototype.create_axes = function() {
    this.x_axis = d3.axisBottom()
      .scale(this.x)
      .tickFormat(dateTickFormat);
    return this.y_axis = d3.axisLeft().scale(this.y).ticks(5);
  };

  ContributorsMasterGraph.prototype.create_svg = function() {
    return this.svg = d3.select("#contributors-master").append("svg").attr("width", this.width + this.MARGIN.left + this.MARGIN.right).attr("height", this.height + this.MARGIN.top + this.MARGIN.bottom).attr("class", "tint-box").append("g").attr("transform", "translate(" + this.MARGIN.left + "," + this.MARGIN.top + ")");
  };

  ContributorsMasterGraph.prototype.create_area = function(x, y) {
    return this.area = d3.area().x(function(d) {
      return x(d.date);
    }).y0(this.height).y1(function(d) {
      d.commits = d.commits || d.additions || d.deletions;
      return y(d.commits);
    });
  };

  ContributorsMasterGraph.prototype.create_brush = function() {
    return this.brush = d3.brushX(this.x).extent([[this.x.range()[0], 0], [this.x.range()[1], this.height]]).on("end", this.update_content);
  };

  ContributorsMasterGraph.prototype.draw_path = function(data) {
    return this.svg.append("path").datum(data).attr("class", "area").attr("d", this.area);
  };

  ContributorsMasterGraph.prototype.add_brush = function() {
    return this.svg.append("g").attr("class", "selection").call(this.brush).selectAll("rect").attr("height", this.height);
  };

  ContributorsMasterGraph.prototype.update_content = function() {
    // d3Event.selection replaces the function brush.empty() calls
    if (d3Event.selection != null) {
      ContributorsGraph.set_x_domain(d3Event.selection.map(this.x.invert));
    } else {
      ContributorsGraph.set_x_domain(this.x_max_domain);
    }
    return $("#brush_change").trigger('change');
  };

  ContributorsMasterGraph.prototype.draw = function() {
    this.process_dates(this.data);
    this.create_scale();
    this.create_axes();
    ContributorsGraph.init_domain(this.data);
    this.x_max_domain = this.x_domain;
    this.set_domain();
    this.create_area(this.x, this.y);
    this.create_svg();
    this.create_brush();
    this.draw_path(this.data);
    this.draw_x_axis();
    this.draw_y_axis();
    return this.add_brush();
  };

  ContributorsMasterGraph.prototype.redraw = function() {
    this.process_dates(this.data);
    ContributorsGraph.set_y_domain(this.data);
    this.set_y_domain();
    this.svg.select("path").datum(this.data);
    this.svg.select("path").attr("d", this.area);
    return this.svg.select(".y.axis").call(this.y_axis);
  };

  return ContributorsMasterGraph;
})(ContributorsGraph);

export const ContributorsAuthorGraph = (function(superClass) {
  extend(ContributorsAuthorGraph, superClass);

  function ContributorsAuthorGraph(data1) {
    this.data = data1;
    // Don't split graph size in half for mobile devices.
    if ($(window).width() < 768) {
      this.width = $('.content').width() - 80;
    } else {
      this.width = ($('.content').width() / 2) - 100;
    }
    this.height = 200;
    this.x = null;
    this.y = null;
    this.x_axis = null;
    this.y_axis = null;
    this.area = null;
    this.svg = null;
    this.list_item = null;
  }

  ContributorsAuthorGraph.prototype.create_scale = function() {
    return ContributorsAuthorGraph.__super__.create_scale.call(this, this.width, this.height);
  };

  ContributorsAuthorGraph.prototype.create_axes = function() {
    this.x_axis = d3.axisBottom()
      .scale(this.x)
      .ticks(8)
      .tickFormat(dateTickFormat);
    return this.y_axis = d3.axisLeft().scale(this.y).ticks(5);
  };

  ContributorsAuthorGraph.prototype.create_area = function(x, y) {
    return this.area = d3.area().x(function(d) {
      var parseDate;
      parseDate = d3.timeParse("%Y-%m-%d");
      return x(parseDate(d));
    }).y0(this.height).y1((function(_this) {
      return function(d) {
        if (_this.data[d] != null) {
          return y(_this.data[d]);
        } else {
          return y(0);
        }
      };
    })(this));
  };

  ContributorsAuthorGraph.prototype.create_svg = function() {
    var persons = document.querySelectorAll('.person');
    this.list_item = persons[persons.length - 1];
    return this.svg = d3.select(this.list_item).append("svg").attr("width", this.width + this.MARGIN.left + this.MARGIN.right).attr("height", this.height + this.MARGIN.top + this.MARGIN.bottom).attr("class", "spark").append("g").attr("transform", "translate(" + this.MARGIN.left + "," + this.MARGIN.top + ")");
  };

  ContributorsAuthorGraph.prototype.draw_path = function(data) {
    return this.svg.append("path").datum(data).attr("class", "area-contributor").attr("d", this.area);
  };

  ContributorsAuthorGraph.prototype.draw = function() {
    this.create_scale();
    this.create_axes();
    this.set_domain();
    this.create_area(this.x, this.y);
    this.create_svg();
    this.draw_path(this.dates);
    this.draw_x_axis();
    return this.draw_y_axis();
  };

  ContributorsAuthorGraph.prototype.redraw = function() {
    this.set_domain();
    this.svg.select("path").datum(this.dates);
    this.svg.select("path").attr("d", this.area);
    this.svg.select(".x.axis").call(this.x_axis);
    return this.svg.select(".y.axis").call(this.y_axis);
  };

  return ContributorsAuthorGraph;
})(ContributorsGraph);
