window.ContributorsStatGraphUtil =
  parse_log: (log) ->
    total = {}
    by_author = {}
    for entry in log
      @add_date(entry.date, total) unless total[entry.date]?
      @add_author(entry.author, by_author) unless by_author[entry.author]?
      @add_date(entry.date, by_author[entry.author]) unless by_author[entry.author][entry.date]
      @store_data(entry, total[entry.date], by_author[entry.author][entry.date])
    total = _.toArray(total)
    by_author = _.toArray(by_author)
    total: total, by_author: by_author

  add_date: (date, collection) ->
    collection[date] = {}
    collection[date].date = date

  add_author: (author, by_author) ->
    by_author[author] = {}
    by_author[author].author = author

  store_data: (entry, total, by_author) ->
    @store_commits(total, by_author)
    @store_additions(entry, total, by_author)
    @store_deletions(entry, total, by_author)

  store_commits: (total, by_author) ->
    @add(total, "commits", 1)
    @add(by_author, "commits", 1)

  add: (collection, field, value) ->
    collection[field] ?= 0
    collection[field] += value

  store_additions: (entry, total, by_author) ->
    entry.additions ?= 0
    @add(total, "additions", entry.additions)
    @add(by_author, "additions", entry.additions)

  store_deletions: (entry, total, by_author) ->
    entry.deletions ?= 0
    @add(total, "deletions", entry.deletions)
    @add(by_author, "deletions", entry.deletions)

  get_total_data: (parsed_log, field) ->
    log = parsed_log.total
    total_data = @pick_field(log, field)
    _.sortBy(total_data, (d) ->
      d.date
    )
  pick_field: (log, field) ->
    total_data = []
    _.each(log, (d) ->
      total_data.push(_.pick(d, [field, 'date']))
    )
    total_data

  get_author_data: (parsed_log, field, date_range = null) ->
    log = parsed_log.by_author
    author_data = []
    _.each(log, (d) ->
      push = {}
      push.author = d.author
      push.dates = {}
      push.commits = push.additions = push.deletions = 0
      _.each(_.omit(d, 'author'), (value, key) ->
        if date_range is null
          push.dates[value.date] = value[field]
          push.commits += value.commits
          push.additions += value.additions
          push.deletions += value.deletions
        else if date_range[0] <= new Date(value.date) <= date_range[1]
          push.dates[value.date] = value[field]
          push.commits += value.commits
          push.additions += value.additions
          push.deletions += value.deletions
      )
      if not _.isEmpty(push.dates)
        author_data.push(push)
    )

    _.sortBy(author_data, (d) ->
      d[field]
    ).reverse()

  