# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete =
  # Emoji
  Emoji:
    data: []
    template: '<li data-value="${insert}">${name} <img alt="${name}" height="20" src="${image}" width="20" /></li>'

  # Team Members
  Members:
    data: []
    url: ''
    params:
      private_token: ''
    template: '<li data-value="${username}">${username} <small>${name}</small></li>'

  # Add GFM auto-completion to all input fields, that accept GFM input.
  setup: ->
    input = $('.js-gfm-input')

    # Emoji
    input.atWho ':',
      data: @Emoji.data
      tpl: @Emoji.template

    # Team Members
    input.atWho '@',
      tpl: @Members.template
      callback: (query, callback) =>
        request_params = $.extend({}, @Members.params, query: query)
        $.getJSON(@Members.url, request_params).done (members) =>
          new_members_data = $.map(members, (m) ->
            username: m.username,
            name: m.name
          )
          callback(new_members_data)

