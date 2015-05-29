#= require d3
#= require stat_graph_contributors_util

class @ContributorsStatGraph
  init: (log) ->
    @parsed_log = ContributorsStatGraphUtil.parse_log(log)
    @set_current_field("commits")
    total_commits = ContributorsStatGraphUtil.get_total_data(@parsed_log, @field)
    author_commits = ContributorsStatGraphUtil.get_author_data(@parsed_log, @field)
    @add_master_graph(total_commits)
    @add_authors_graph(author_commits)
    @change_date_header()
  add_master_graph: (total_data) ->
    @master_graph = new ContributorsMasterGraph(total_data)
    @master_graph.draw()
  add_authors_graph: (author_data) ->
    @authors = []
    limited_author_data = author_data.slice(0, 100)
    _.each(limited_author_data, (d) =>
      author_header = @create_author_header(d)
      $(".contributors-list").append(author_header)
      @authors[d.author_name] = author_graph = new ContributorsAuthorGraph(d.dates)
      author_graph.draw()
    )
  format_author_commit_info: (author) ->
    commits = $('<span/>', {
      class: 'graph-author-commits-count'
    })
    commits.text(author.commits + " commits")
    $('<span/>').append(commits)

  create_author_header: (author) ->
    list_item = $('<li/>', {
      class: 'person'
      style: 'display: block;'
    })
    author_name = $('<h4>' + author.author_name + '</h4>')
    author_email = $('<p class="graph-author-email">' + author.author_email + '</p>')
    author_commit_info_span = $('<span/>', {
      class: 'commits'
    })
    author_commit_info = @format_author_commit_info(author)
    author_commit_info_span.html(author_commit_info)
    list_item.append(author_name)
    list_item.append(author_email)
    list_item.append(author_commit_info_span)
    list_item
  redraw_master: ->
    total_data = ContributorsStatGraphUtil.get_total_data(@parsed_log, @field)
    @master_graph.set_data(total_data)
    @master_graph.redraw()
  redraw_authors: ->
    $("ol").html("")
    x_domain = ContributorsGraph.prototype.x_domain
    author_commits = ContributorsStatGraphUtil.get_author_data(@parsed_log, @field, x_domain)
    _.each(author_commits, (d) =>
      @redraw_author_commit_info(d)
      $(@authors[d.author_name].list_item).appendTo("ol")
      @authors[d.author_name].set_data(d.dates)
      @authors[d.author_name].redraw()
    )
  set_current_field: (field) ->
    @field = field
  change_date_header: ->
    x_domain = ContributorsGraph.prototype.x_domain
    print_date_format = d3.time.format("%B %e %Y")
    print = print_date_format(x_domain[0]) + " - " + print_date_format(x_domain[1])
    $("#date_header").text(print)
  redraw_author_commit_info: (author) ->
    author_list_item = $(@authors[author.author_name].list_item)
    author_commit_info = @format_author_commit_info(author)
    author_list_item.find("span").html(author_commit_info)
