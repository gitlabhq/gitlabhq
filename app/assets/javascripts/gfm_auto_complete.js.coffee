# Creates the variables for setting up GFM auto-completion

# Emoji
data      = []
template  = "<li data-value='${insert}'>${name} <img alt='${name}' height='20' src='${image}' width='20' /></li>"
window.autocompleteEmoji = {data, template}

# Team Members
url     = '';
params  = {private_token: '', page: 1}
window.autocompleteMembers = {data, url, params}

# Add GFM auto-completion to all input fields, that accept GFM input.
window.setupGfmAutoComplete = ->
  $input = $('.js-gfm-input')

  # Emoji
  $input.atWho ':',
    data: autocompleteEmoji.data,
    tpl: autocompleteEmoji.template

  # Team Members
  $input.atWho '@', (query, callback) ->
    (getMoreMembers = ->
      $.getJSON(autocompleteMembers.url, autocompleteMembers.params).success (members) ->
        # pick the data we need
        newMembersData = $.map members, (m) -> m.name

        # add the new page of data to the rest
        $.merge autocompleteMembers.data, newMembersData

        # show the pop-up with a copy of the current data
        callback autocompleteMembers.data[..]

        # are we past the last page?
        if newMembersData.length is 0
          # set static data and stop callbacks
          $input.atWho '@',
            data: autocompleteMembers.data
            callback: null
        else
          # get next page
          getMoreMembers()

      # so the next request gets the next page
      autocompleteMembers.params.page += 1
    ).call()
