class @NamespaceSelect
  constructor: ->
    namespaceFormatResult = (namespace) ->
      markup = "<div class='namespace-result'>"
      markup += "<span class='namespace-kind'>" + namespace.kind + "</span>"
      markup += "<span class='namespace-path'>" + namespace.path + "</span>"
      markup += "</div>"
      markup

    formatSelection = (namespace) ->
      namespace.kind + ": " + namespace.path

    $('.ajax-namespace-select').each (i, select) ->
      $(select).select2
        placeholder: "Search for namespace"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) ->
          Api.namespaces query.term, (namespaces) ->
            data = { results: namespaces }
            query.callback(data)

        dropdownCssClass: "ajax-namespace-dropdown"
        formatResult: namespaceFormatResult
        formatSelection: formatSelection
