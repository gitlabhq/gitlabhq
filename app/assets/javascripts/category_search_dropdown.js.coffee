@categorySearchDropdown =
  init: ->
    $categorySearchDropdown = $('.category-search-dropdown')
    $searchInput = $('#search')
    $dropDown = $categorySearchDropdown.closest('.dropdown')
    $categorySearchParent = $categorySearchDropdown.parent()

    $searchInput.on 'focusin click', (e) ->
      if $(event.currentTarget).has('#search') and not $dropDown.hasClass('has-value')
        $categorySearchParent.removeClass('hidden')
        $categorySearchParent.siblings('.dropdown-select').addClass('hidden')
        $dropDown.addClass('open')

    $searchInput.on 'keypress', (e) ->
      if $(event.currentTarget).has('#search')
        $categorySearchParent.addClass('hidden')
        $categorySearchParent.siblings('.dropdown-select').removeClass('hidden')

$ ->
  categorySearchDropdown.init()
