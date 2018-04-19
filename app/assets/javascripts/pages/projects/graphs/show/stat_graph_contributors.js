/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, one-var, camelcase, one-var-declaration-per-line, quotes, no-param-reassign, quote-props, comma-dangle, prefer-template, max-len, no-return-assign, no-shadow */

import $ from 'jquery';
import _ from 'underscore';
import { n__, s__, createDateTimeFormat, sprintf } from '~/locale';
import { ContributorsGraph, ContributorsAuthorGraph, ContributorsMasterGraph } from './stat_graph_contributors_graph';
import ContributorsStatGraphUtil from './stat_graph_contributors_util';

export default (function() {
  function ContributorsStatGraph() {
    this.dateFormat = createDateTimeFormat({ year: 'numeric', month: 'long', day: 'numeric' });
  }

  ContributorsStatGraph.prototype.init = function(log) {
    var author_commits, total_commits;
    this.parsed_log = ContributorsStatGraphUtil.parse_log(log);
    this.set_current_field("commits");
    total_commits = ContributorsStatGraphUtil.get_total_data(this.parsed_log, this.field);
    author_commits = ContributorsStatGraphUtil.get_author_data(this.parsed_log, this.field);
    this.add_master_graph(total_commits);
    this.add_authors_graph(author_commits);
    return this.change_date_header();
  };

  ContributorsStatGraph.prototype.add_master_graph = function(total_data) {
    this.master_graph = new ContributorsMasterGraph(total_data);
    return this.master_graph.draw();
  };

  ContributorsStatGraph.prototype.add_authors_graph = function(author_data) {
    var limited_author_data;
    this.authors = [];
    limited_author_data = author_data.slice(0, 100);
    return _.each(limited_author_data, (function(_this) {
      return function(d) {
        var author_graph, author_header;
        author_header = _this.create_author_header(d);
        $(".contributors-list").append(author_header);
        _this.authors[d.author_name] = author_graph = new ContributorsAuthorGraph(d.dates);
        return author_graph.draw();
      };
    })(this));
  };

  ContributorsStatGraph.prototype.format_author_commit_info = function(author) {
    var commits;
    commits = $('<span/>', {
      "class": 'graph-author-commits-count'
    });
    commits.text(n__('%d commit', '%d commits', author.commits));
    return $('<span/>').append(commits);
  };

  ContributorsStatGraph.prototype.create_author_header = function(author) {
    var author_commit_info, author_commit_info_span, author_email, author_name, list_item;
    list_item = $('<li/>', {
      "class": 'person',
      style: 'display: block;'
    });
    author_name = $('<h4>' + author.author_name + '</h4>');
    author_email = $('<p class="graph-author-email">' + author.author_email + '</p>');
    author_commit_info_span = $('<span/>', {
      "class": 'commits'
    });
    author_commit_info = this.format_author_commit_info(author);
    author_commit_info_span.html(author_commit_info);
    list_item.append(author_name);
    list_item.append(author_email);
    list_item.append(author_commit_info_span);
    return list_item;
  };

  ContributorsStatGraph.prototype.redraw_master = function() {
    var total_data;
    total_data = ContributorsStatGraphUtil.get_total_data(this.parsed_log, this.field);
    this.master_graph.set_data(total_data);
    return this.master_graph.redraw();
  };

  ContributorsStatGraph.prototype.redraw_authors = function() {
    var author_commits, x_domain;
    $("ol").html("");
    x_domain = ContributorsGraph.prototype.x_domain;
    author_commits = ContributorsStatGraphUtil.get_author_data(this.parsed_log, this.field, x_domain);
    return _.each(author_commits, (function(_this) {
      return function(d) {
        _this.redraw_author_commit_info(d);
        if (_this.authors[d.author_name] != null) {
          $(_this.authors[d.author_name].list_item).appendTo("ol");
          _this.authors[d.author_name].set_data(d.dates);
          return _this.authors[d.author_name].redraw();
        }
        return '';
      };
    })(this));
  };

  ContributorsStatGraph.prototype.set_current_field = function(field) {
    return this.field = field;
  };

  ContributorsStatGraph.prototype.change_date_header = function() {
    const x_domain = ContributorsGraph.prototype.x_domain;
    const formattedDateRange = sprintf(
      s__('ContributorsPage|%{startDate} – %{endDate}'),
      {
        startDate: this.dateFormat.format(new Date(x_domain[0])),
        endDate: this.dateFormat.format(new Date(x_domain[1])),
      },
    );
    return $('#date_header').text(formattedDateRange);
  };

  ContributorsStatGraph.prototype.redraw_author_commit_info = function(author) {
    var author_commit_info, author_list_item, $author;
    $author = this.authors[author.author_name];
    if ($author != null) {
      author_list_item = $(this.authors[author.author_name].list_item);
      author_commit_info = this.format_author_commit_info(author);
      return author_list_item.find("span").html(author_commit_info);
    }
    return '';
  };

  return ContributorsStatGraph;
})();
