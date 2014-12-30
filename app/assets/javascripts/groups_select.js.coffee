class @GroupsSelect
  constructor: ->
    $('.ajax-groups-select').each (i, select) =>
      skip_ldap = $(select).hasClass('skip_ldap')

      $(select).select2
        placeholder: "Search for a group"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) ->
          Api.groups query.term, skip_ldap, (groups) ->
            data = { results: groups }
            query.callback(data)

        initSelection: (element, callback) ->
          id = $(element).val()
          if id isnt ""
            Api.group(id, callback)


        formatResult: (args...) =>
          @formatResult(args...)
        formatSelection: (args...) =>
          @formatSelection(args...)
        dropdownCssClass: "ajax-groups-dropdown"
        escapeMarkup: (m) -> # we do not want to escape markup since we are displaying html in results
          m

  formatResult: (group) ->
    if group.avatar_url
      avatar = group.avatar_url
    else
      avatar = gon.default_avatar_url

    "<div class='group-result'>
       <div class='group-name'>#{group.name}</div>
       <div class='group-path'>#{group.path}</div>
     </div>"

  formatSelection: (group) ->
    group.name
