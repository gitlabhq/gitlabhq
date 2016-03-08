class @UsersSelect
  constructor: ->
    @usersPath = "/autocomplete/users.json"
    @userPath = "/autocomplete/users/:id.json"

    $('.js-user-search').each (i, dropdown) =>
      @projectId = $(dropdown).data('project-id')
      @showCurrentUser = $(dropdown).data('current-user')
      showNullUser = $(dropdown).data('null-user')
      showAnyUser = $(dropdown).data('any-user')
      firstUser = $(dropdown).data('first-user')
      selectedId = $(dropdown).data('selected')

      $(dropdown).glDropdown(
        data: (term, callback) =>
          @users term, (users) =>
            if term.length is 0
              showDivider = 0

              if firstUser
                # Move current user to the front of the list
                for obj, index in users
                  if obj.username == firstUser
                    users.splice(index, 1)
                    users.unshift(obj)
                    break

              if showNullUser
                showDivider += 1
                users.unshift(
                  name: 'Unassigned',
                  id: 0
                )

              if showAnyUser
                showDivider += 1
                name = showAnyUser
                name = 'Any User' if name == true
                anyUser = {
                  name: name,
                  id: null
                }
                users.unshift(anyUser)

            if showDivider
              users.splice(showDivider, 0, "divider")

            # Send the data back
            callback users
        filterable: true
        filterRemote: true
        search:
          fields: ['name', 'username']
        selectable: true
        fieldName: $(dropdown).data('field-name')
        clicked: ->
          if $(dropdown).hasClass "js-filter-submit"
            $(dropdown).parents('form').submit()
        renderRow: (user) ->
          username = if user.username then "@#{user.username}" else ""
          avatar = if user.avatar_url then user.avatar_url else false
          selected = if user.id is selectedId then "is-active" else ""
          img = ""

          if avatar
            img = "<img src='#{avatar}' class='avatar avatar-inline' width='30' />"

          "<li>
            <a href='#' class='dropdown-menu-user-link #{selected}'>
              #{img}
              <strong class='dropdown-menu-user-full-name'>
                #{user.name}
              </strong>
              <span class='dropdown-menu-user-username'>
                #{username}
              </span>
            </a>
          </li>"
      )

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
                  id: 0
                }
                data.results.unshift(nullUser)

              if showAnyUser
                name = showAnyUser
                name = 'Any User' if name == true
                anyUser = {
                  name: name,
                  id: null
                }
                data.results.unshift(anyUser)

            if showEmailUser && data.results.length == 0 && query.term.match(/^[^@]+@[^@]+$/)
              emailUser = {
                name: "Invite \"#{query.term}\"",
                username: query.term,
                id: query.term
              }
              data.results.unshift(emailUser)

            query.callback(data)

        initSelection: (args...) =>
          @initSelection(args...)
        formatResult: (args...) =>
          @formatResult(args...)
        formatSelection: (args...) =>
          @formatSelection(args...)
        dropdownCssClass: "ajax-users-dropdown"
        escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
          m

  initSelection: (element, callback) ->
    id = $(element).val()
    if id == "0"
      nullUser = { name: 'Unassigned' }
      callback(nullUser)
    else if id != ""
      @user(id, callback)

  formatResult: (user) ->
    if user.avatar_url
      avatar = user.avatar_url
    else
      avatar = gon.default_avatar_url

    "<div class='user-result #{'no-username' unless user.username}'>
       <div class='user-image'><img class='avatar s24' src='#{avatar}'></div>
       <div class='user-name'>#{user.name}</div>
       <div class='user-username'>#{user.username || ""}</div>
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
    url = gon.relative_url_root.replace(/\/$/, '') + url if gon.relative_url_root?
    return url
