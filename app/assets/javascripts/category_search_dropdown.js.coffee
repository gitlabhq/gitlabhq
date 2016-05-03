class CategorySearchDropdown

  constructor: ->
    @search = $('.search')
    @searchInput = $('#search')
    @dropdown = @search.find('.dropdown')
    @dropdownContent = @dropdown.find('.dropdown-content')

    @searchInput.on 'focus click', (e) =>
      if gon.current_user_id
        @showCategoryDropDown()

    @searchInput.on 'keypress', (e) =>
      if not $(e.currentTarget).val()
        @restoreMenu()

    @searchInput.on 'locationBadgeRemoved locationBadgeAdded', (e) =>
      if e.type is 'locationBadgeRemoved'
        @search.removeClass('has-location-badge')
      @showCategoryDropDown()

  showCategoryDropDown: ->
    $currentProjectOpts = @search.find('.current-project-opts')
    $generalOpts = @search.find('.dashboard-opts')
    userId = gon.current_user_id

    if $currentProjectOpts.length and @search.hasClass('has-location-badge')
      issueUrl = $currentProjectOpts.data('user-issues-path')
      mrUrl = $currentProjectOpts.data('user-mr-path')
      projectName = $currentProjectOpts.data('project-name')
    else if $generalOpts.length
      issueUrl = $generalOpts.data('user-issues-path')
      mrUrl = $generalOpts.data('user-mr-path')
      projectName = 'Dashboard'

    html = @categorySearchDropdownTemplate(issueUrl, mrUrl, projectName, userId)
    @dropdownContent.html(html)

  restoreMenu: ->
    html = "<ul>
              <li><a class='dropdown-menu-empty-link is-focused'>Loading...</a></li>
            </ul>"
    @dropdownContent.html(html)

  categorySearchDropdownTemplate: (issueUrl, mrUrl, name, userId) ->
    "<ul class='category-dropdown-search'>
      <li class='dropdown-header'><span>Go to in #{name}</span></li>
      <li><a href='#{issueUrl}/?assignee_id=#{userId}'>Issues assigned to me</a></li>
      <li><a href='#{issueUrl}/?author_id=#{userId}'>Issues I've created</a></li>
      <li class='divider'><li>
      <li><a href='#{mrUrl}/?assignee_id=#{userId}'>Merge requests assigned to me</a></li>
      <li><a href='#{mrUrl}/?author_id=#{userId}'>Merge requests I've created</a></li>
    </ul>"

$ ->
  new CategorySearchDropdown()
