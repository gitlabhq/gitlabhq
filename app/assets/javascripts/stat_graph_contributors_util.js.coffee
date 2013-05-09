window.ContributorsStatGraphUtil =
  total: {}
  by_author: {}
  get_stat_graph_log: ->
    StatGraph.get_log()
  parse_log: (log) ->
    for entry in log
      @total[entry.date] ?= {}
      @total[entry.date].date ?= entry.date
      @by_author[entry.author] ?= {} 
      @by_author[entry.author].author ?= entry.author
      @by_author[entry.author][entry.date] ?= {}
      @by_author[entry.author][entry.date].date ?= entry.date
      @store_commits(entry)
      @store_additions(entry)
      @store_deletions(entry)
    @total = _.toArray(@total)
    @by_author = _.toArray(@by_author)
    total: @total, by_author: @by_author
  store_commits: (entry) ->
    @total[entry.date].total ?= 0
    @by_author[entry.author][entry.date].total ?= 0
    @total[entry.date].total += 1
    @by_author[entry.author][entry.date].total += 1
  store_additions: (entry) ->
    @total[entry.date].additions ?= 0
    @by_author[entry.author][entry.date].additions ?= 0
    if entry.additions?
      @total[entry.date].additions += entry.additions
      @by_author[entry.author][entry.date].additions += entry.additions
  store_deletions: (entry) ->
    @total[entry.date].deletions ?= 0
    @by_author[entry.author][entry.date].deletions ?= 0
    if entry.deletions?
      @total[entry.date].deletions += entry.deletions
      @by_author[entry.author][entry.date].deletions += entry.deletions
  get_total_data: (parsed_log, field) ->
    log = parsed_log.total
    total_data = []
    _.each(log, (d) ->
      total_data.push(_.pick(d, [field, 'date']))
    )
    _.sortBy(total_data, (d) ->
      d.date
    )
  get_author_data: (parsed_log, field, date_range = null) ->
    log = parsed_log.by_author
    author_data = []
    _.each(log, (d) ->
      push = {}
      push.author = d.author
      push.dates = {}
      push.total = push.additions = push.deletions = 0
      _.each(_.omit(d, 'author'), (value, key) ->
        if date_range is null
          push.dates[value.date] = value[field]
          push.total += value.total
          push.additions += value.additions
          push.deletions += value.deletions
        else if date_range[0] <= new Date(value.date) <= date_range[1]
          push.dates[value.date] = value[field]
          push.total += value.total
          push.additions += value.additions
          push.deletions += value.deletions
      )
      if not jQuery.isEmptyObject(push.dates)
        author_data.push(push)
    )

    _.sortBy(author_data, (d) ->
      d[field]
    ).reverse()