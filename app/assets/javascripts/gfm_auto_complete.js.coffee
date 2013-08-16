# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete =
  # private_token: ''
  dataSource: ''
  # Emoji
  Emoji:
    assetBase: ''
    template: '<li data-value="${insert}">${name} <img alt="${name}" height="20" src="${image}" width="20" /></li>'

  # Team Members
  Members:
    template: '<li data-value="${username}">${username} <small>${name}</small></li>'

  Issues:
    template: '<li data-value="${id}"><small>${id}</small> ${title} </li>'

  # Add GFM auto-completion to all input fields, that accept GFM input.
  setup: ->
    input = $('.js-gfm-input')

    # Emoji
    input.atwho
      at: ':'
      tpl: @Emoji.template
      callbacks:
        before_save: (emojis) =>
          $.map emojis, (em) => name: em, insert: em+ ':', image: "#{@Emoji.assetBase}/#{em}.png"

    # Team Members
    input.atwho
      at: '@'
      tpl: @Members.template
      search_key: 'search'
      callbacks:
        before_save: (members) =>
          $.map members, (m) => name: m.name, username: m.username, search: "#{m.username} #{m.name}"

    input.atwho
      at: '#'
      alias: 'issues'
      search_key: 'search'
      tpl: @Issues.template
      callbacks:
        before_save: (issues) ->
          $.map issues, (i) -> id: i.id, title: sanitize(i.title), search: "#{i.id} #{i.title}"

    input.one "focus", =>
      $.getJSON(@dataSource).done (data) ->
        # load members
        input.atwho 'load', "@", data.members
        # load issues
        input.atwho 'load', "issues", data.issues
        # load emojis
        input.atwho 'load', ":", data.emojis
