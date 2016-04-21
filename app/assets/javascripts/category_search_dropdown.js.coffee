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

    $searchInput.on 'locationBadgeRemoved locationBadgeAdded', (e) ->
      if e.type is 'locationBadgeAdded'
        $categorySearchDropdown.find('.project-category-search').removeClass('hidden')
        $categorySearchDropdown.find('.general-category-search').addClass('hidden')
      else if e.type is 'locationBadgeRemoved'
        $categorySearchDropdown.find('.project-category-search').addClass('hidden')
        $categorySearchDropdown.find('.general-category-search').removeClass('hidden')

$ ->
  categorySearchDropdown.init()
