@projectUsersSelect =
  init: ->
    $('.ajax-project-users-select').each (i, select) ->
      project_id = $('body').data('project-id')

      $(select).select2
        placeholder: $(select).data('placeholder') || "Search for a user"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) ->
          Api.projectUsers project_id, query.term, (users) ->
            data = { results: users }

            nullUser = {
              name: 'Unassigned',
              avatar: null,
              username: 'none',
              id: ''
            }

            data.results.unshift(nullUser)

            query.callback(data)

        initSelection: (element, callback) ->
          id = $(element).val()
          if id isnt ""
            Api.user(id, callback)


        formatResult: projectUsersSelect.projectUserFormatResult
        formatSelection: projectUsersSelect.projectUserFormatSelection
        dropdownCssClass: "ajax-project-users-dropdown"
        dropdownAutoWidth: true
        escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
          m

  projectUserFormatResult: (user) ->
    if user.avatar_url
      avatar = user.avatar_url
    else if gon.gravatar_enabled
      avatar = gon.gravatar_url
      avatar = avatar.replace('%{hash}', md5(user.email))
      avatar = avatar.replace('%{size}', '24')
    else
      avatar = gon.relative_url_root + "/assets/no_avatar.png"

    if user.id == ''
      avatarMarkup = ''
    else
      avatarMarkup = "<div class='user-image'><img class='avatar s24' src='#{avatar}'></div>"

    "<div class='user-result'>
       #{avatarMarkup}
       <div class='user-name'>#{user.name}</div>
       <div class='user-username'>#{user.username}</div>
     </div>"

  projectUserFormatSelection: (user) ->
    user.name

$ ->
  projectUsersSelect.init()
