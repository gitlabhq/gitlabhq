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


  $('.ajax-users-select').select2
    placeholder: "Search for a user"
    minimumInputLength: 0
    ajax: # instead of writing the function to execute the request we use Select2's convenient helper
      url: "/api/v3/users.json"
      dataType: "json"
      data: (term, page) ->
        search: term # search term
        per_page: 10
        private_token: gon.api_token

      results: (data, page) -> # parse the results into the format expected by Select2.
        # since we are using custom formatting functions we do not need to alter remote JSON data
        results: data

    initSelection: (element, callback) ->
      id = $(element).val()
      if id isnt ""
        $.ajax("http://api.rottentomatoes.com/api/public/v1.0/users/" + id + ".json",
          data:
            apikey: "ju6z9mjyajq2djue3gbvv26t"

          dataType: "jsonp"
        ).done (data) ->
          callback data


    formatResult: userFormatResult # omitted for brevity, see the source of this page
    #formatSelection: userFormatSelection # omitted for brevity, see the source of this page
    dropdownCssClass: "ajax-users-dropdown" # apply css that makes the dropdown taller
    escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
      m

