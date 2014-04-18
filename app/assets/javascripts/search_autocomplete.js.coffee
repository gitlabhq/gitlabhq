class SearchAutocomplete
  constructor: (search_autocomplete_path, project_id, project_ref) ->
    project_id = '' unless project_id
    project_ref = '' unless project_ref
    query = "?project_id=" + project_id + "&project_ref=" + project_ref

    $("#search").autocomplete
      source: search_autocomplete_path + query
      minLength: 1
      select: (event, ui) ->
        location.href = ui.item.url

@SearchAutocomplete = SearchAutocomplete
