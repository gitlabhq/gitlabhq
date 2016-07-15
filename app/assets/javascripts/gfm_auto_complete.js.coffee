# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete =
  dataLoading: false
  dataLoaded: false
  cachedData: {}
  dataSource: ''

  # Emoji
  Emoji:
    template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'

  # Team Members
  Members:
    template: '<li>${username} <small>${title}</small></li>'

  Labels:
    template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'

  # Issues and MergeRequests
  Issues:
    template: '<li><small>${id}</small> ${title}</li>'

  # Milestones
  Milestones:
    template: '<li>${title}</li>'

  Loading:
    template: '<li><i class="fa fa-refresh fa-spin"></i> Loading...</li>'

  DefaultOptions:
    sorter: (query, items, searchKey) ->
      return items if items[0].name? and items[0].name is 'loading'

      $.fn.atwho.default.callbacks.sorter(query, items, searchKey)
    filter: (query, data, searchKey) ->
      return data if data[0] is 'loading'

      $.fn.atwho.default.callbacks.filter(query, data, searchKey)
    beforeInsert: (value) ->
      if not GitLab.GfmAutoComplete.dataLoaded
        @at
      else
        value

  # Add GFM auto-completion to all input fields, that accept GFM input.
  setup: (wrap) ->
    @input = $('.js-gfm-input')

    # destroy previous instances
    @destroyAtWho()

    # set up instances
    @setupAtWho()

    if @dataSource
      if not @dataLoading and not @cachedData
        @dataLoading = true

        # We should wait until initializations are done
        # and only trigger the last .setup since
        # The previous .dataSource belongs to the previous issuable
        # and the last one will have the **proper** .dataSource property
        # TODO: Make this a singleton and turn off events when moving to another page
        setTimeout( =>
          fetch = @fetchData(@dataSource)
          fetch.done (data) =>
            @dataLoading = false
            @loadData(data)
        , 1000)

      if @cachedData?
        @loadData(@cachedData)

  setupAtWho: ->
    # Emoji
    @input.atwho
      at: ':'
      displayTpl: (value) =>
        if value.path?
          @Emoji.template
        else
          @Loading.template
      insertTpl: ':${name}:'
      data: ['loading']
      callbacks:
        sorter: @DefaultOptions.sorter
        filter: @DefaultOptions.filter
        beforeInsert: @DefaultOptions.beforeInsert

    # Team Members
    @input.atwho
      at: '@'
      displayTpl: (value) =>
        if value.username?
          @Members.template
        else
          @Loading.template
      insertTpl: '${atwho-at}${username}'
      searchKey: 'search'
      data: ['loading']
      callbacks:
        sorter: @DefaultOptions.sorter
        filter: @DefaultOptions.filter
        beforeInsert: @DefaultOptions.beforeInsert
        beforeSave: (members) ->
          $.map members, (m) ->
            return m if not m.username?

            title = m.name
            title += " (#{m.count})" if m.count

            username: m.username
            title:    sanitize(title)
            search:   sanitize("#{m.username} #{m.name}")

    @input.atwho
      at: '#'
      alias: 'issues'
      searchKey: 'search'
      displayTpl:  (value) =>
        if value.title?
          @Issues.template
        else
          @Loading.template
      data: ['loading']
      insertTpl: '${atwho-at}${id}'
      callbacks:
        sorter: @DefaultOptions.sorter
        filter: @DefaultOptions.filter
        beforeInsert: @DefaultOptions.beforeInsert
        beforeSave: (issues) ->
          $.map issues, (i) ->
            return i if not i.title?

            id:     i.iid
            title:  sanitize(i.title)
            search: "#{i.iid} #{i.title}"

    @input.atwho
      at: '%'
      alias: 'milestones'
      searchKey: 'search'
      displayTpl:  (value) =>
        if value.title?
          @Milestones.template
        else
          @Loading.template
      insertTpl: '${atwho-at}"${title}"'
      data: ['loading']
      callbacks:
        beforeSave: (milestones) ->
          $.map milestones, (m) ->
            return m if not m.title?

            id:     m.iid
            title:  sanitize(m.title)
            search: "#{m.title}"

    @input.atwho
      at: '!'
      alias: 'mergerequests'
      searchKey: 'search'
      displayTpl:  (value) =>
        if value.title?
          @Issues.template
        else
          @Loading.template
      data: ['loading']
      insertTpl: '${atwho-at}${id}'
      callbacks:
        sorter: @DefaultOptions.sorter
        filter: @DefaultOptions.filter
        beforeInsert: @DefaultOptions.beforeInsert
        beforeSave: (merges) ->
          $.map merges, (m) ->
            return m if not m.title?

            id:     m.iid
            title:  sanitize(m.title)
            search: "#{m.iid} #{m.title}"

    @input.atwho
      at: '~'
      alias: 'labels'
      searchKey: 'search'
      displayTpl: @Labels.template
      insertTpl: '${atwho-at}${title}'
      callbacks:
        beforeSave: (merges) ->
          sanitizeLabelTitle = (title)->
            if /[\w\?&]+\s+[\w\?&]+/g.test(title)
              "\"#{sanitize(title)}\""
            else
              sanitize(title)

          $.map merges, (m) ->
            title: sanitizeLabelTitle(m.title)
            color: m.color
            search: "#{m.title}"

  destroyAtWho: ->
    @input.atwho('destroy')

  fetchData: (dataSource) ->
    $.getJSON(dataSource)

  loadData: (data) ->
    @cachedData = data
    @dataLoaded = true

    # load members
    @input.atwho 'load', '@', data.members
    # load issues
    @input.atwho 'load', 'issues', data.issues
    # load milestones
    @input.atwho 'load', 'milestones', data.milestones
    # load merge requests
    @input.atwho 'load', 'mergerequests', data.mergerequests
    # load emojis
    @input.atwho 'load', ':', data.emojis
    # load labels
    @input.atwho 'load', '~', data.labels

    # This trigger at.js again
    # otherwise we would be stuck with loading until the user types
    $(':focus').trigger('keyup')
