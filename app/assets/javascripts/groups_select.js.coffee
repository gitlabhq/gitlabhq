class @GroupsSelect
  constructor: ->
    $('.ajax-groups-select').each (i, select) =>
      skip_group = $(select).data("skip-group")
      url = $(select).data("url")

      $(select).select2
        placeholder: "Search for a group"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) ->
          $.ajax(
            url: url
            data:
              search: query.term
              per_page: 20
            dataType: "json"
          ).done (groups) ->
            data = { results: [] }
            
            for group in groups
              continue if skip_group && group.path == skip_group

              data.results.push(group)
              
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
