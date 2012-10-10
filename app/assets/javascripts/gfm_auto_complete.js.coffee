
###
  Creates the variables for setting up GFM auto-completion
###
# Emoji
window.autocompleteEmojiData = [];
window.autocompleteEmojiTemplate = "<li data-value='${insert}'>${name} <img alt='${name}' height='20' src='${image}' width='20' /></li>";

# Team Members
window.autocompleteMembersUrl = "";
window.autocompleteMembersParams =
  private_token: ""
  page: 1
window.autocompleteMembersData = [];



###
  Add GFM auto-completion to all input fields, that accept GFM input.
###
window.setupGfmAutoComplete = ->
  ###
    Emoji
  ###
  $('.gfm-input').atWho ':',
    data: autocompleteEmojiData,
    tpl: autocompleteEmojiTemplate

  ###
    Team Members
  ###
  $('.gfm-input').atWho '@', (query, callback) ->
    (getMoreMembers = ->
      $.getJSON(autocompleteMembersUrl, autocompleteMembersParams)
        .success (members) ->
          # pick the data we need
          newMembersData = $.map members, (m) -> m.name

          # add the new page of data to the rest
          $.merge autocompleteMembersData, newMembersData

          # show the pop-up with a copy of the current data
          callback autocompleteMembersData[..]

          # are we past the last page?
          if newMembersData.length == 0
            # set static data and stop callbacks
            $('.gfm-input').atWho '@',
              data: autocompleteMembersData
              callback: null
          else
            # get next page
            getMoreMembers()

      # so the next request gets the next page
      autocompleteMembersParams.page += 1;
    ).call();