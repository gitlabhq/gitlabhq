class SearchAutocomplete
  constructor: (json) ->
    $("#search").autocomplete
      source: json
      select: (event, ui) ->
        location.href = ui.item.url

@SearchAutocomplete = SearchAutocomplete
