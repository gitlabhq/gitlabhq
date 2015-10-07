class @TreeView
  constructor: ->
    @initKeyNav()

    # Code browser tree slider
    # Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
    $(".tree-content-holder .tree-item").on 'click', (e) ->
      if (e.target.nodeName != "A")
        path = $('.tree-item-file-name a', this).attr('href')
        Turbolinks.visit(path)

    # Show the "Loading commit data" for only the first element
    $('span.log_loading:first').removeClass('hide')

  initKeyNav: ->
    li = $("tr.tree-item")
    liSelected = null
    $('body').keydown (e) ->
      if $("input:focus").length > 0 && (e.which == 38 || e.which == 40)
        return false

      if e.which is 40
        if liSelected
          next = liSelected.next()
          if next.length > 0
            liSelected.removeClass "selected"
            liSelected = next.addClass("selected")
        else
          liSelected = li.eq(0).addClass("selected")

        $(liSelected).focus()
      else if e.which is 38
        if liSelected
          next = liSelected.prev()
          if next.length > 0
            liSelected.removeClass "selected"
            liSelected = next.addClass("selected")
        else
          liSelected = li.last().addClass("selected")

        $(liSelected).focus()
      else if e.which is 13
        path = $('.tree-item.selected .tree-item-file-name a').attr('href')
        if path then Turbolinks.visit(path)
