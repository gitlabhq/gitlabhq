class @Sidebar
  constructor: (currentUser) ->
    @addEventListeners()

  addEventListeners: ->
    $('aside').on('click', '.sidebar-collapsed-icon', @sidebarCollapseClicked)
    $('.dropdown').on('hidden.gl.dropdown', @sidebarDropdownHidden)
    $('.dropdown').on('loading.gl.dropdown', @sidebarDropdownLoading)
    $('.dropdown').on('loaded.gl.dropdown', @sidebarDropdownLoaded)

  sidebarDropdownLoading: (e) ->
    $sidebarCollapsedIcon = $(@).closest('.block').find('.sidebar-collapsed-icon')
    img = $sidebarCollapsedIcon.find('img')
    i = $sidebarCollapsedIcon.find('i')
    $loading = $('<i class="fa fa-spinner fa-spin"></i>')
    if img.length
      img.before($loading)
      img.hide()
    else if i.length
      i.before($loading)
      i.hide()

  sidebarDropdownLoaded: (e) ->
    $sidebarCollapsedIcon = $(@).closest('.block').find('.sidebar-collapsed-icon')
    img = $sidebarCollapsedIcon.find('img')
    $sidebarCollapsedIcon.find('i.fa-spin').remove()
    i = $sidebarCollapsedIcon.find('i')
    if img.length
      img.show()
    else
      i.show()


  sidebarCollapseClicked: (e) ->
    e.preventDefault()
    $block = $(@).closest('.block')

    $('aside')
      .find('.gutter-toggle')
      .trigger('click')
    $editLink = $block.find('.edit-link')

    if $editLink.length
      $editLink.trigger('click')
      $block.addClass('collapse-after-update')
      $('.page-with-sidebar').addClass('with-overlay')

  sidebarDropdownHidden: (e) ->
    $block = $(@).closest('.block')
    if $block.hasClass('collapse-after-update')
      $block.removeClass('collapse-after-update')
      $('.page-with-sidebar').removeClass('with-overlay')
      $('aside')
        .find('.gutter-toggle')
        .trigger('click')