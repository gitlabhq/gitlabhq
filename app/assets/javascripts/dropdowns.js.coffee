$ ->
  $('[data-toggle="dropdown"]').each ->
    $dropdown = $(@).parent()
    $menu = $dropdown.find('.dropdown-menu')

    $dropdown.on 'shown.bs.dropdown', ->
      dropdownRight = $menu.offset().left + $menu.outerWidth()

      if dropdownRight >= $(window).width()
        $menu.addClass 'dropdown-menu-align-right'
