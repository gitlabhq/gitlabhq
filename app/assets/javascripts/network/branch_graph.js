/* eslint-disable func-names, space-before-function-paren, no-var, wrap-iife, quotes, comma-dangle, one-var, one-var-declaration-per-line, no-mixed-operators, no-loop-func, no-floating-decimal, consistent-return, no-unused-vars, prefer-template, prefer-arrow-callback, camelcase, max-len */

import $ from 'jquery';
import { __ } from '../locale';
import axios from '../lib/utils/axios_utils';
import flash from '../flash';
import Raphael from './raphael';

export default (function() {
  function BranchGraph(element1, options1) {
    this.element = element1;
    this.options = options1;
    this.scrollTop = this.scrollTop.bind(this);
    this.scrollBottom = this.scrollBottom.bind(this);
    this.scrollRight = this.scrollRight.bind(this);
    this.scrollLeft = this.scrollLeft.bind(this);
    this.scrollUp = this.scrollUp.bind(this);
    this.scrollDown = this.scrollDown.bind(this);
    this.preparedCommits = {};
    this.mtime = 0;
    this.mspace = 0;
    this.parents = {};
    this.colors = ["#000"];
    this.offsetX = 150;
    this.offsetY = 20;
    this.unitTime = 30;
    this.unitSpace = 10;
    this.prev_start = -1;
    this.load();
  }

  BranchGraph.prototype.load = function() {
    axios.get(this.options.url)
      .then(({ data }) => {
        $(".loading", this.element).hide();
        this.prepareData(data.days, data.commits);
        this.buildGraph();
      })
      .catch(() => __('Error fetching network graph.'));
  };

  BranchGraph.prototype.prepareData = function(days, commits) {
    var c, ch, cw, j, len, ref;
    this.days = days;
    this.commits = commits;
    this.collectParents();
    this.graphHeight = $(this.element).height();
    this.graphWidth = $(this.element).width();
    ch = Math.max(this.graphHeight, this.offsetY + this.unitTime * this.mtime + 150);
    cw = Math.max(this.graphWidth, this.offsetX + this.unitSpace * this.mspace + 300);
    this.r = Raphael(this.element.get(0), cw, ch);
    this.top = this.r.set();
    this.barHeight = Math.max(this.graphHeight, this.unitTime * this.days.length + 320);
    ref = this.commits;
    for (j = 0, len = ref.length; j < len; j += 1) {
      c = ref[j];
      if (c.id in this.parents) {
        c.isParent = true;
      }
      this.preparedCommits[c.id] = c;
      this.markCommit(c);
    }
    return this.collectColors();
  };

  BranchGraph.prototype.collectParents = function() {
    var c, j, len, p, ref, results;
    ref = this.commits;
    results = [];
    for (j = 0, len = ref.length; j < len; j += 1) {
      c = ref[j];
      this.mtime = Math.max(this.mtime, c.time);
      this.mspace = Math.max(this.mspace, c.space);
      results.push((function() {
        var l, len1, ref1, results1;
        ref1 = c.parents;
        results1 = [];
        for (l = 0, len1 = ref1.length; l < len1; l += 1) {
          p = ref1[l];
          this.parents[p[0]] = true;
          results1.push(this.mspace = Math.max(this.mspace, p[1]));
        }
        return results1;
      }).call(this));
    }
    return results;
  };

  BranchGraph.prototype.collectColors = function() {
    var k, results;
    k = 0;
    results = [];
    while (k < this.mspace) {
      this.colors.push(Raphael.getColor(.8));
      // Skipping a few colors in the spectrum to get more contrast between colors
      Raphael.getColor();
      Raphael.getColor();
      results.push(k += 1);
    }
    return results;
  };

  BranchGraph.prototype.buildGraph = function() {
    var cuday, cumonth, day, j, len, mm, r, ref;
    r = this.r;
    cuday = 0;
    cumonth = "";
    r.rect(0, 0, 40, this.barHeight).attr({
      fill: "#222"
    });
    r.rect(40, 0, 30, this.barHeight).attr({
      fill: "#444"
    });
    ref = this.days;
    for (mm = j = 0, len = ref.length; j < len; mm = (j += 1)) {
      day = ref[mm];
      if (cuday !== day[0] || cumonth !== day[1]) {
        // Dates
        r.text(55, this.offsetY + this.unitTime * mm, day[0]).attr({
          font: "12px Monaco, monospace",
          fill: "#BBB"
        });
        cuday = day[0];
      }
      if (cumonth !== day[1]) {
        // Months
        r.text(20, this.offsetY + this.unitTime * mm, day[1]).attr({
          font: "12px Monaco, monospace",
          fill: "#EEE"
        });
        cumonth = day[1];
      }
    }
    this.renderPartialGraph();
    return this.bindEvents();
  };

  BranchGraph.prototype.renderPartialGraph = function() {
    var commit, end, i, isGraphEdge, start, x, y;
    start = Math.floor((this.element.scrollTop() - this.offsetY) / this.unitTime) - 10;
    if (start < 0) {
      isGraphEdge = true;
      start = 0;
    }
    end = start + 40;
    if (this.commits.length < end) {
      isGraphEdge = true;
      end = this.commits.length;
    }
    if (this.prev_start === -1 || Math.abs(this.prev_start - start) > 10 || isGraphEdge) {
      i = start;
      this.prev_start = start;
      while (i < end) {
        commit = this.commits[i];
        i += 1;
        if (commit.hasDrawn !== true) {
          x = this.offsetX + this.unitSpace * (this.mspace - commit.space);
          y = this.offsetY + this.unitTime * commit.time;
          this.drawDot(x, y, commit);
          this.drawLines(x, y, commit);
          this.appendLabel(x, y, commit);
          this.appendAnchor(x, y, commit);
          commit.hasDrawn = true;
        }
      }
      return this.top.toFront();
    }
  };

  BranchGraph.prototype.bindEvents = function() {
    var element;
    element = this.element;
    return $(element).scroll((function(_this) {
      return function(event) {
        return _this.renderPartialGraph();
      };
    })(this));
  };

  BranchGraph.prototype.scrollDown = function() {
    this.element.scrollTop(this.element.scrollTop() + 50);
    return this.renderPartialGraph();
  };

  BranchGraph.prototype.scrollUp = function() {
    this.element.scrollTop(this.element.scrollTop() - 50);
    return this.renderPartialGraph();
  };

  BranchGraph.prototype.scrollLeft = function() {
    this.element.scrollLeft(this.element.scrollLeft() - 50);
    return this.renderPartialGraph();
  };

  BranchGraph.prototype.scrollRight = function() {
    this.element.scrollLeft(this.element.scrollLeft() + 50);
    return this.renderPartialGraph();
  };

  BranchGraph.prototype.scrollBottom = function() {
    return this.element.scrollTop(this.element.find('svg').height());
  };

  BranchGraph.prototype.scrollTop = function() {
    return this.element.scrollTop(0);
  };

  BranchGraph.prototype.appendLabel = function(x, y, commit) {
    var label, r, rect, shortrefs, text, textbox, triangle;
    if (!commit.refs) {
      return;
    }
    r = this.r;
    shortrefs = commit.refs;
    // Truncate if longer than 15 chars
    if (shortrefs.length > 17) {
      shortrefs = shortrefs.substr(0, 15) + "…";
    }
    text = r.text(x + 4, y, shortrefs).attr({
      "text-anchor": "start",
      font: "10px Monaco, monospace",
      fill: "#FFF",
      title: commit.refs
    });
    textbox = text.getBBox();
    // Create rectangle based on the size of the textbox
    rect = r.rect(x, y - 7, textbox.width + 5, textbox.height + 5, 4).attr({
      fill: "#000",
      "fill-opacity": .5,
      stroke: "none"
    });
    triangle = r.path(["M", x - 5, y, "L", x - 15, y - 4, "L", x - 15, y + 4, "Z"]).attr({
      fill: "#000",
      "fill-opacity": .5,
      stroke: "none"
    });
    label = r.set(rect, text);
    label.transform(["t", -rect.getBBox().width - 15, 0]);
    // Set text to front
    return text.toFront();
  };

  BranchGraph.prototype.appendAnchor = function(x, y, commit) {
    var anchor, options, r, top;
    r = this.r;
    top = this.top;
    options = this.options;
    anchor = r.circle(x, y, 10).attr({
      fill: "#000",
      opacity: 0,
      cursor: "pointer"
    }).click(function() {
      return window.open(options.commit_url.replace("%s", commit.id), "_blank");
    }).hover(function() {
      this.tooltip = r.commitTooltip(x + 5, y, commit);
      return top.push(this.tooltip.insertBefore(this));
    }, function() {
      return this.tooltip && this.tooltip.remove() && delete this.tooltip;
    });
    return top.push(anchor);
  };

  BranchGraph.prototype.drawDot = function(x, y, commit) {
    var avatar_box_x, avatar_box_y, r;
    r = this.r;
    r.circle(x, y, 3).attr({
      fill: this.colors[commit.space],
      stroke: "none"
    });
    avatar_box_x = this.offsetX + this.unitSpace * this.mspace + 10;
    avatar_box_y = y - 10;
    r.rect(avatar_box_x, avatar_box_y, 20, 20).attr({
      stroke: this.colors[commit.space],
      "stroke-width": 2
    });
    r.image(commit.author.icon, avatar_box_x, avatar_box_y, 20, 20);
    return r.text(this.offsetX + this.unitSpace * this.mspace + 35, y, commit.message.split("\n")[0]).attr({
      "text-anchor": "start",
      font: "14px Monaco, monospace"
    });
  };

  BranchGraph.prototype.drawLines = function(x, y, commit) {
    var arrow, color, i, j, len, offset, parent, parentCommit, parentX1, parentX2, parentY, r, ref, results, route;
    r = this.r;
    ref = commit.parents;
    results = [];
    for (i = j = 0, len = ref.length; j < len; i = (j += 1)) {
      parent = ref[i];
      parentCommit = this.preparedCommits[parent[0]];
      parentY = this.offsetY + this.unitTime * parentCommit.time;
      parentX1 = this.offsetX + this.unitSpace * (this.mspace - parentCommit.space);
      parentX2 = this.offsetX + this.unitSpace * (this.mspace - parent[1]);
      // Set line color
      if (parentCommit.space <= commit.space) {
        color = this.colors[commit.space];
      } else {
        color = this.colors[parentCommit.space];
      }
      // Build line shape
      if (parent[1] === commit.space) {
        offset = [0, 5];
        arrow = "l-2,5,4,0,-2,-5,0,5";
      } else if (parent[1] < commit.space) {
        offset = [3, 3];
        arrow = "l5,0,-2,4,-3,-4,4,2";
      } else {
        offset = [-3, 3];
        arrow = "l-5,0,2,4,3,-4,-4,2";
      }
      // Start point
      route = ["M", x + offset[0], y + offset[1]];
      // Add arrow if not first parent
      if (i > 0) {
        route.push(arrow);
      }
      // Circumvent if overlap
      if (commit.space !== parentCommit.space || commit.space !== parent[1]) {
        route.push("L", parentX2, y + 10, "L", parentX2, parentY - 5);
      }
      // End point
      route.push("L", parentX1, parentY);
      results.push(r.path(route).attr({
        stroke: color,
        "stroke-width": 2
      }));
    }
    return results;
  };

  BranchGraph.prototype.markCommit = function(commit) {
    var r, x, y;
    if (commit.id === this.options.commit_id) {
      r = this.r;
      x = this.offsetX + this.unitSpace * (this.mspace - commit.space);
      y = this.offsetY + this.unitTime * commit.time;
      r.path(["M", x + 5, y, "L", x + 15, y + 4, "L", x + 15, y - 4, "Z"]).attr({
        fill: "#000",
        "fill-opacity": .5,
        stroke: "none"
      });
      // Displayed in the center
      return this.element.scrollTop(y - this.graphHeight / 2);
    }
  };

  return BranchGraph;
})();
