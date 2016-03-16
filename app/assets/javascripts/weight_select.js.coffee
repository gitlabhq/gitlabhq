class @WeightSelect
  constructor: ->
    $('.js-weight-select').each (i, dropdown) ->
      $(dropdown).glDropdown(
        selectable: true
        fieldName: $(dropdown).data("field-name")
        id: (obj, el) ->
          $(el).data "id"
        clicked: ->
          if $(dropdown).is ".js-filter-submit"
            $(dropdown).parents('form').submit()
      )
