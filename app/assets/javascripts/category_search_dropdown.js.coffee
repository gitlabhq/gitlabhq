@categorySearchDropdown =
  init: ->
    $categorySearchDropdown = $('.category-search-dropdown')
    $searchInput = $('#search')
    $dropDown = $categorySearchDropdown.closest('.dropdown')
    $categorySearchParent = $categorySearchDropdown.parent()

    $categorySearchDropdown.on 'click', 'li', (e) -> e.stopPropagation()

    $searchInput.on 'focusin click', (e) ->
      e.stopPropagation()
      if $(event.currentTarget).has('#search') and not $dropDown.hasClass('has-value')
        $categorySearchParent.removeClass('hidden')
        $categorySearchParent.siblings('.dropdown-select').addClass('hidden')
        $dropDown.addClass('open')

    $searchInput.on 'keypress', (e) ->
      e.stopPropagation()
      if $(event.currentTarget).has('#search')
        $categorySearchParent.addClass('hidden')
        $categorySearchParent.siblings('.dropdown-select').removeClass('hidden')

    $searchInput.on 'focusout', (e) ->
      e.stopPropagation()
      $categorySearchParent.addClass('hidden')

$ ->
  categorySearchDropdown.init()
