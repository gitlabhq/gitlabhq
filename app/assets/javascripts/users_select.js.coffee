class @UsersSelect
  constructor: ->
    @usersPath = "/autocomplete/users.json"
    @userPath = "/autocomplete/users/:id.json"

    $('.ajax-users-select').each (i, select) =>
      @projectId = $(select).data('project-id')
      @groupId = $(select).data('group-id')
      @showCurrentUser = $(select).data('current-user')
      showNullUser = $(select).data('null-user')
      showAnyUser = $(select).data('any-user')
      showEmailUser = $(select).data('email-user')
      firstUser = $(select).data('first-user')

      $(select).select2
        placeholder: "Search for a user"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) =>
          @users query.term, (users) =>
            data = { results: users }

            if query.term.length == 0
              if firstUser
                # Move current user to the front of the list
                for obj, index in data.results
                  if obj.username == firstUser
                    data.results.splice(index, 1)
                    data.results.unshift(obj)
                    break

              if showNullUser
                nullUser = {
                  name: 'Unassigned',
                  avatar: null,
                  username: 'none',
                  id: 0
                }
                data.results.unshift(nullUser)

              if showAnyUser
                anyUser = {
                  name: 'Any',
                  avatar: null,
                  username: 'none',
                  id: null
                }
                data.results.unshift(anyUser)

            if showEmailUser && data.results.length == 0 && query.term.match(/^[^@]+@[^@]+$/)
              emailUser = {
                name: "Invite \"#{query.term}\"",
                avatar: null,
                username: query.term,
                id: query.term
              }
              data.results.unshift(emailUser)

            query.callback(data)

        initSelection: (element, callback) =>
          id = $(element).val()
          if id != "" && id != "0"
            @user(id, callback)

        formatResult: (args...) =>
          @formatResult(args...)
        formatSelection: (args...) =>
          @formatSelection(args...)
        dropdownCssClass: "ajax-users-dropdown"
        escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
          m

  formatResult: (user) ->
    if user.avatar_url
      avatar = user.avatar_url
    else
      avatar = gon.default_avatar_url

    "<div class='user-result'>
       <div class='user-image'><img class='avatar s24' src='#{avatar}'></div>
       <div class='user-name'>#{user.name}</div>
       <div class='user-username'>#{user.username}</div>
     </div>"

  formatSelection: (user) ->
    user.name

  user: (user_id, callback) =>
    url = @buildUrl(@userPath)
    url = url.replace(':id', user_id)

    $.ajax(
      url: url
      dataType: "json"
    ).done (user) ->
      callback(user)

  # Return users list. Filtered by query
  # Only active users retrieved
  users: (query, callback) =>
    url = @buildUrl(@usersPath)

    $.ajax(
      url: url
      data:
        search: query
        per_page: 20
        active: true
        project_id: @projectId
        group_id: @groupId
        current_user: @showCurrentUser
      dataType: "json"
    ).done (users) ->
      callback(users)

  buildUrl: (url) ->
    url = gon.relative_url_root + url if gon.relative_url_root?
    return url
