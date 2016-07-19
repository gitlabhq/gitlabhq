class @UsersSelect
  constructor: (currentUser) ->
    @usersPath = "/autocomplete/users.json"
    @userPath = "/autocomplete/users/:id.json"
    if currentUser?
      @currentUser = JSON.parse(currentUser)

    $('.js-user-search').each (i, dropdown) =>
      $dropdown = $(dropdown)
      @projectId = $dropdown.data('project-id')
      @showCurrentUser = $dropdown.data('current-user')
      showNullUser = $dropdown.data('null-user')
      showAnyUser = $dropdown.data('any-user')
      firstUser = $dropdown.data('first-user')
      @authorId = $dropdown.data('author-id')
      selectedId = $dropdown.data('selected')
      defaultLabel = $dropdown.data('default-label')
      issueURL = $dropdown.data('issueUpdate')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      abilityName = $dropdown.data('ability-name')
      $value = $block.find('.value')
      $collapsedSidebar = $block.find('.sidebar-collapsed-user')
      $loading = $block.find('.block-loading').fadeOut()

      $block.on('click', '.js-assign-yourself', (e) =>
        e.preventDefault()
        assignTo(@currentUser.id)
      )

      assignTo = (selected) ->
        data = {}
        data[abilityName] = {}
        data[abilityName].assignee_id = if selected? then selected else null
        $loading
          .fadeIn()
        $dropdown.trigger('loading.gl.dropdown')
        $.ajax(
          type: 'PUT'
          dataType: 'json'
          url: issueURL
          data: data
        ).done (data) ->
          $dropdown.trigger('loaded.gl.dropdown')
          $loading.fadeOut()
          $selectbox.hide()

          if data.assignee
            user =
              name: data.assignee.name
              username: data.assignee.username
              avatar: data.assignee.avatar_url
          else
            user =
              name: 'Unassigned'
              username: ''
              avatar: ''
          $value.html(assigneeTemplate(user))

          $collapsedSidebar
            .attr('title', user.name)
            .tooltip('fixTitle')

          $collapsedSidebar.html(collapsedAssigneeTemplate(user))


      collapsedAssigneeTemplate = _.template(
        '<% if( avatar ) { %>
        <a class="author_link" href="/u/<%- username %>">
          <img width="24" class="avatar avatar-inline s24" alt="" src="<%- avatar %>">
        </a>
        <% } else { %>
        <i class="fa fa-user"></i>
        <% } %>'
      )

      assigneeTemplate = _.template(
        '<% if (username) { %>
        <a class="author_link bold" href="/u/<%- username %>">
          <% if( avatar ) { %>
          <img width="32" class="avatar avatar-inline s32" alt="" src="<%- avatar %>">
          <% } %>
          <span class="author"><%- name %></span>
          <span class="username">
            @<%- username %>
          </span>
        </a>
          <% } else { %>
        <span class="no-value assign-yourself">
          No assignee -
          <a href="#" class="js-assign-yourself">
            assign yourself
          </a>
        </span>
          <% } %>'
      )

      $dropdown.glDropdown(
        data: (term, callback) =>
          isAuthorFilter = $('.js-author-search')

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
                  beforeDivider: true
                  name: 'Unassigned',
                  id: 0
                )

              if showAnyUser
                showDivider += 1
                name = showAnyUser
                name = 'Any User' if name == true
                anyUser = {
                  beforeDivider: true
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
        fieldName: $dropdown.data('field-name')

        toggleLabel: (selected) ->
          if selected && 'id' of selected
            if selected.text then selected.text else selected.name
          else
            defaultLabel

        inputId: 'issue_assignee_id'

        hidden: (e) ->
          $selectbox.hide()
          # display:block overrides the hide-collapse rule
          $value.css('display', '')

        clicked: (user) ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is page is 'projects:merge_requests:index'
          if $dropdown.hasClass('js-filter-bulk-update')
            return

          if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
            selectedId = user.id
            Issuable.filterResults $dropdown.closest('form')
          else if $dropdown.hasClass 'js-filter-submit'
            $dropdown.closest('form').submit()
          else
            selected = $dropdown
              .closest('.selectbox')
              .find("input[name='#{$dropdown.data('field-name')}']").val()
            assignTo(selected)

        renderRow: (user) ->
          username = if user.username then "@#{user.username}" else ""
          avatar = if user.avatar_url then user.avatar_url else false
          selected = if user.id is selectedId then "is-active" else ""
          img = ""

          if user.beforeDivider?
            "<li>
              <a href='#' class='#{selected}'>
                #{user.name}
              </a>
            </li>"
          else
            if avatar
              img = "<img src='#{avatar}' class='avatar avatar-inline' width='30' />"

          # split into three parts so we can remove the username section if nessesary
          listWithName = "<li>
            <a href='#' class='dropdown-menu-user-link #{selected}'>
              #{img}
              <strong class='dropdown-menu-user-full-name'>
                #{user.name}
              </strong>"

          listWithUserName = "<span class='dropdown-menu-user-username'>
                #{username}
              </span>"
          listClosingTags = "</a>
          </li>"


          if username is ''
            listWithUserName = ''

          listWithName + listWithUserName + listClosingTags
      )

    $('.ajax-users-select').each (i, select) =>
      @skipLdap = $(select).hasClass('skip_ldap')
      @projectId = $(select).data('project-id')
      @groupId = $(select).data('group-id')
      @showCurrentUser = $(select).data('current-user')
      @pushCodeToProtectedBranches = $(select).data('push-code-to-protected-branches')
      @authorId = $(select).data('author-id')
      @skipUsers = $(select).data('skip-users')
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
        skip_ldap: @skipLdap
        current_user: @showCurrentUser
        push_code_to_protected_branches: @pushCodeToProtectedBranches
        author_id: @authorId
        skip_users: @skipUsers
      dataType: "json"
    ).done (users) ->
      callback(users)

  buildUrl: (url) ->
    url = gon.relative_url_root.replace(/\/$/, '') + url if gon.relative_url_root?
    return url
