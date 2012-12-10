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
      page: 1
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
        (getMoreMembers = =>
          $.getJSON(@Members.url, @Members.params).done (members) =>
            # pick the data we need
            newMembersData = $.map(members, (m) ->
              username: m.username
              name: m.name
            )

            # add the new page of data to the rest
            $.merge(@Members.data, newMembersData)

            # show the pop-up with a copy of the current data
            callback(@Members.data[..])

            # are we past the last page?
            if newMembersData.length is 0
              # set static data and stop callbacks
              input.atWho '@',
                data: @Members.data
                callback: null
            else
              # get next page
              getMoreMembers()

          # so the next callback requests the next page
          @Members.params.page += 1
        ).call()
