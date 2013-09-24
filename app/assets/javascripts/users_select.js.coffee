$ ->
  userFormatResult = (user) ->
    avatar = gon.gravatar_url
    avatar = avatar.replace('%{hash}', md5(user.email))
    avatar = avatar.replace('%{size}', '24')

    markup = "<div class='user-result'>"
    markup += "<div class='user-image'><img class='avatar s24' src='" + avatar + "'></div>"
    markup += "<div class='user-name'>" + user.name + "</div>"
    markup += "<div class='user-username'>" + user.username + "</div>"
    markup += "</div>"
    markup

  userFormatSelection = (user) ->
    user.name

  $('.ajax-users-select').each (i, select) ->
    $(select).select2
      placeholder: "Search for a user"
      multiple: $(select).hasClass('multiselect')
      minimumInputLength: 0
      query: (query) ->
        Api.users query.term, (users) ->
          data = { results: users }
          query.callback(data)

      initSelection: (element, callback) ->
        id = $(element).val()
        if id isnt ""
          Api.user(id, callback)


      formatResult: userFormatResult
      formatSelection: userFormatSelection
      dropdownCssClass: "ajax-users-dropdown"
      escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
        m
