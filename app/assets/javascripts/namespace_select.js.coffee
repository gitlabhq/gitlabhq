class @NamespaceSelect
  constructor: (opts) ->
    {
      @dropdown
    } = opts

    showAny = true
    fieldName = 'namespace_id'

    if @dropdown.attr 'data-field-name'
     fieldName = @dropdown.data 'fieldName'

    if @dropdown.attr 'data-show-any'
      showAny = @dropdown.data 'showAny'

    @dropdown.glDropdown(
      filterable: true
      selectable: true
      filterRemote: true
      search:
        fields: ['path']
      fieldName: fieldName
      toggleLabel: (selected) ->
        return if not selected.id? then selected.text else "#{selected.kind}: #{selected.path}"
      data: (term, dataCallback) ->
        Api.namespaces term, (namespaces) ->
          if showAny
            anyNamespace =
              text: 'Any namespace'
              id: null

            namespaces.unshift(anyNamespace)
            namespaces.splice 1, 0, 'divider'

          dataCallback(namespaces)
      text: (namespace) ->
        return if not namespace.id? then namespace.text else "#{namespace.kind}: #{namespace.path}"
      renderRow: @renderRow
      clicked: @onSelectItem
    )

  onSelectItem: (item, el, e) =>
    e.preventDefault()

class @NamespaceSelects
  constructor: (opts = {}) ->
    {
      @$dropdowns = $('.js-namespace-select')
    } = opts

    @$dropdowns.each (i, dropdown) ->
      $dropdown = $(dropdown)

      new NamespaceSelect(
        dropdown: $dropdown
      )
