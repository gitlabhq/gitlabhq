# Creates the variables for setting up GFM auto-completion

window.GitLab ?= {}
GitLab.GfmAutoComplete ?= {}

# Emoji
data      = []
template  = "<li data-value='${insert}'>${name} <img alt='${name}' height='20' src='${image}' width='20' /></li>"
GitLab.GfmAutoComplete.Emoji = {data, template}

# Team Members
data      = []
url     = '';
params  = {private_token: '', page: 1}
GitLab.GfmAutoComplete.Members = {data, url, params}

# Add GFM auto-completion to all input fields, that accept GFM input.
GitLab.GfmAutoComplete.setup = ->
  input = $('.js-gfm-input')

  # Emoji
  input.atWho ':',
    data: GitLab.GfmAutoComplete.Emoji.data,
    tpl: GitLab.GfmAutoComplete.Emoji.template

  # Team Members
  input.atWho '@', (query, callback) ->
    (getMoreMembers = ->
      $.getJSON(GitLab.GfmAutoComplete.Members.url, GitLab.GfmAutoComplete.Members.params)
        .success (members) ->
          # pick the data we need
          newMembersData = $.map(members, (m) -> m.name )

          # add the new page of data to the rest
          $.merge(GitLab.GfmAutoComplete.Members.data, newMembersData)

          # show the pop-up with a copy of the current data
          callback(GitLab.GfmAutoComplete.Members.data[..])

          # are we past the last page?
          if newMembersData.length is 0
            # set static data and stop callbacks
            input.atWho '@',
              data: GitLab.GfmAutoComplete.Members.data
              callback: null
          else
            # get next page
            getMoreMembers()

      # so the next request gets the next page
      GitLab.GfmAutoComplete.Members.params.page += 1
    ).call()
