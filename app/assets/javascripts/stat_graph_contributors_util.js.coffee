window.ContributorsStatGraphUtil =
  parse_log: (log) ->
    total = {}
    by_author = {}
    by_email = {}
    for entry in log
      @add_date(entry.date, total) unless total[entry.date]?

      data = by_author[entry.author_name] || by_email[entry.author_email]      
      data ?= @add_author(entry, by_author, by_email)

      @add_date(entry.date, data) unless data[entry.date]
      @store_data(entry, total[entry.date], data[entry.date])
    total = _.toArray(total)
    by_author = _.toArray(by_author)
    total: total, by_author: by_author

  add_date: (date, collection) ->
    collection[date] = {}
    collection[date].date = date

  add_author: (author, by_author, by_email) ->
    data = {}
    data.author_name = author.author_name
    data.author_email = author.author_email
    by_author[author.author_name] = data
    by_email[author.author_email] = data

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

    _.each(log, (log_entry) =>
      parsed_log_entry = @parse_log_entry(log_entry, field, date_range)
      if not _.isEmpty(parsed_log_entry.dates)
        author_data.push(parsed_log_entry)
    )

    _.sortBy(author_data, (d) ->
      d[field]
    ).reverse()

  parse_log_entry: (log_entry, field, date_range) ->
    parsed_entry = {}
    parsed_entry.author_name = log_entry.author_name
    parsed_entry.author_email = log_entry.author_email
    parsed_entry.dates = {}
    parsed_entry.commits = parsed_entry.additions = parsed_entry.deletions = 0
    _.each(_.omit(log_entry, 'author_name', 'author_email'), (value, key) =>
      if @in_range(value.date, date_range)
        parsed_entry.dates[value.date] = value[field]
        parsed_entry.commits += value.commits
        parsed_entry.additions += value.additions
        parsed_entry.deletions += value.deletions
    )
    return parsed_entry

  in_range: (date, date_range) ->
    if date_range is null || date_range[0] <= new Date(date) <= date_range[1]
      true
    else
      false