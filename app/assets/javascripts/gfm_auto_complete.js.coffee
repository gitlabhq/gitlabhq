# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete =
  dataLoading: false

  dataSource: ''

  # Emoji
  Emoji:
    template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'

  # Team Members
  Members:
    template: '<li>${username} <small>${title}</small></li>'

  Labels:
    template: '<li>${title} <div style="background-color:${color};height:15px;width:15px;display:inline-block;float:right">
              </div></li>'

  # Issues and MergeRequests
  Issues:
    template: '<li><small>${id}</small> ${title}</li>'

  # Add GFM auto-completion to all input fields, that accept GFM input.
  setup: (wrap) ->
    @input = $('.js-gfm-input')

    # destroy previous instances
    @destroyAtWho()

    # set up instances
    @setupAtWho()

    if @dataSource
      if !@dataLoading
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


  setupAtWho: ->
    # Emoji
    @input.atwho
      at: ':'
      displayTpl: @Emoji.template
      insertTpl: ':${name}:'

    # Team Members
    @input.atwho
      at: '@'
      displayTpl: @Members.template
      insertTpl: '${atwho-at}${username}'
      searchKey: 'search'
      callbacks:
        beforeSave: (members) ->
          $.map members, (m) ->
            title = m.name
            title += " (#{m.count})" if m.count

            username: m.username
            title:    sanitize(title)
            search:   sanitize("#{m.username} #{m.name}")

    @input.atwho
      at: '#'
      alias: 'issues'
      searchKey: 'search'
      displayTpl: @Issues.template
      insertTpl: '${atwho-at}${id}'
      callbacks:
        beforeSave: (issues) ->
          $.map issues, (i) ->
            id:     i.iid
            title:  sanitize(i.title)
            search: "#{i.iid} #{i.title}"

    @input.atwho
      at: '!'
      alias: 'mergerequests'
      searchKey: 'search'
      displayTpl: @Issues.template
      insertTpl: '${atwho-at}${id}'
      callbacks:
        beforeSave: (merges) ->
          $.map merges, (m) ->
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
            if /\w+\s+\w+/g.test(title)
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
    # load members
    @input.atwho 'load', '@', data.members
    # load issues
    @input.atwho 'load', 'issues', data.issues
    # load merge requests
    @input.atwho 'load', 'mergerequests', data.mergerequests
    # load emojis
    @input.atwho 'load', ':', data.emojis
    # load labels
    @input.atwho 'load', '~', data.labels
