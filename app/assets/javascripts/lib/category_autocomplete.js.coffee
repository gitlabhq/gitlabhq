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

  _renderItem: (ul, item) ->
    # Highlight occurrences
    item.label = item.label.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + $.ui.autocomplete.escapeRegex(this.term) + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");

    return $( "<li></li>" )
        .data( "item.autocomplete", item )
        .append( "<a>#{item.label}</a>" )
        .appendTo( ul );

  _resizeMenu: ->
    if (isNaN(this.options.maxShowItems))
      return

    ul = this.menu.element.css(overflowX: '', overflowY: '', width: '', maxHeight: '')

    lis = ul.children('li').css('whiteSpace', 'nowrap');

    if (lis.length > this.options.maxShowItems)
      ulW = ul.prop('clientWidth')

      ul.css(
            overflowX: 'hidden'
            overflowY: 'auto'
            maxHeight: lis.eq(0).outerHeight() * this.options.maxShowItems + 1
          )

      barW = ulW - ul.prop('clientWidth');
      ul.width('+=' + barW);

    # Original code from jquery.ui.autocomplete.js _resizeMenu()
    ul.outerWidth(Math.max(ul.outerWidth() + 1, this.element.outerWidth()));
  )
