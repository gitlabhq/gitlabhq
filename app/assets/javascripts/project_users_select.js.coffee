class @ProjectUsersSelect
  constructor: ->
    $('.ajax-project-users-select').each (i, select) =>
      project_id = $(select).data('project-id') || $('body').data('project-id')

      $(select).select2
        placeholder: $(select).data('placeholder') || "Search for a user"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) ->
          Api.projectUsers project_id, query.term, (users) ->
            data = { results: users }

            if query.term.length == 0
              nullUser = {
                name: 'Unassigned',
                avatar: null,
                username: 'none',
                id: -1
              }

              data.results.unshift(nullUser)

            query.callback(data)

        initSelection: (element, callback) ->
          id = $(element).val()
          if id != "" && id != "-1"
            Api.user(id, callback)


        formatResult: (args...) =>
          @formatResult(args...)
        formatSelection: (args...) =>
          @formatSelection(args...)
        dropdownCssClass: "ajax-project-users-dropdown"
        dropdownAutoWidth: true
        escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
          m

  formatResult: (user) ->
    if user.avatar_url
      avatar = user.avatar_url
    else
      avatar = gon.default_avatar_url

    avatarMarkup = "<div class='user-image'><img class='avatar s24' src='#{avatar}'></div>"

    "<div class='user-result'>
       #{avatarMarkup}
       <div class='user-name'>#{user.name}</div>
       <div class='user-username'>#{user.username}</div>
     </div>"

  formatSelection: (user) ->
    user.name
