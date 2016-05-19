class @CategorySearchDropdown

  constructor: ->

    @registerElements()
    @bindEvents()


  registerElements: ->

    @searchWidget    = $ '.search'
    @searchInput     = $ '#search'
    @dropdown        = @searchWidget.find '.dropdown'
    @dropdownContent = @dropdown.find '.dropdown-content'


  bindEvents: ->

    @searchInput.on 'focus', (e) =>
      if gon.current_user_id
        @showCategoryDropDown()

    @searchInput.on 'keyup', (e) =>
      unless e.currentTarget.value
        @restoreMenu()

    @searchInput.on 'locationBadgeAdded', =>
      @showCategoryDropDown()

    @searchInput.on 'locationBadgeRemoved', =>
      @searchWidget.removeClass 'has-location-badge'
      @showCategoryDropDown()


  showCategoryDropDown: ->

    userId           = gon.current_user_id
    projectSlug      = gl.utils.getProjectSlug()
    hasLocationBadge = @searchWidget.hasClass 'has-location-badge'

    if gl.projectOptions and projectSlug and hasLocationBadge
      { issuesPath, mrPath, projectName } = gl.projectOptions[projectSlug]

    else if gl.dashboardOptions
      { issuesPath, mrPath } = gl.dashboardOptions
      projectName = 'Dashboard'

    html = @categorySearchDropdownTemplate issuesPath, mrPath, projectName, userId
    @dropdownContent.html html


  restoreMenu: ->

    html = "<ul><li><a class='dropdown-menu-empty-link is-focused'>Loading...</a></li></ul>"
    @dropdownContent.html html


  categorySearchDropdownTemplate: (issuesPath, mrPath, name, userId) ->

    "<ul class='category-dropdown-search'>
      <li class='dropdown-header'><span>Go to in #{name}</span></li>
      <li><a href='#{issuesPath}/?assignee_id=#{userId}'>Issues assigned to me</a></li>
      <li><a href='#{issuesPath}/?author_id=#{userId}'>Issues I've created</a></li>
      <li class='divider'><li>
      <li><a href='#{mrPath}/?assignee_id=#{userId}'>Merge requests assigned to me</a></li>
      <li><a href='#{mrPath}/?author_id=#{userId}'>Merge requests I've created</a></li>
    </ul>"
