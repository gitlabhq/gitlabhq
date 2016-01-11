# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete =
  dataSource: ''

  # Emoji
  Emoji:
    template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'

  # Team Members
  Members:
    template: '<li>${username} <small>${title}</small></li>'

  # Issues and MergeRequests
  Issues:
    template: '<li><small>${id}</small> ${title}</li>'

  # Add GFM auto-completion to all input fields, that accept GFM input.
  setup: ->
    input = $('.js-gfm-input')

    # Emoji
    input.atwho
      at: ':'
      displayTpl: @Emoji.template
      insertTpl: ':${name}:'

    # Team Members
    input.atwho
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

    input.atwho
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

    input.atwho
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

    if @dataSource
      $.getJSON(@dataSource).done (data) ->
        # load members
        input.atwho 'load', '@', data.members
        # load issues
        input.atwho 'load', 'issues', data.issues
        # load merge requests
        input.atwho 'load', 'mergerequests', data.mergerequests
        # load emojis
        input.atwho 'load', ':', data.emojis
