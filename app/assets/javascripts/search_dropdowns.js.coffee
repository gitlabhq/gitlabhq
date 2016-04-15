class @SearchDropdowns
  constructor: ->
    $('.js-search-group-dropdown').glDropdown(
      selectable: true
      filterable: true
    )
