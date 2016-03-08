$.widget( "custom.catcomplete",  $.ui.autocomplete,
  _create: ->
    @_super();
    @widget().menu("option", "items", "> :not(.ui-autocomplete-category)")

  _renderMenu: (ul, items) ->
    currentCategory = ''
    $.each items, (index, item) =>
      if item.category isnt currentCategory
        ul.append("<li class='ui-autocomplete-category'>#{item.category}</li>")
        currentCategory = item.category

      li = @_renderItemData(ul, item)

      if item.category?
        li.attr('aria-label', item.category + " : " + item.label)
  )
