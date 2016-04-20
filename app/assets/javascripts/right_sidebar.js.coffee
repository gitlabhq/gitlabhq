class @Sidebar
  constructor: (currentUser) ->
    @sidebar = $('aside')

    @addEventListeners()

  addEventListeners: ->
    _this = @
    @sidebar.on 'click', '.sidebar-collapsed-icon', (e) ->
      e.preventDefault()
      $block = $(@).closest('.block')
      _this.openDropdown($block);

    $('.dropdown').on 'hidden.gl.dropdown', (e) ->
      e.preventDefault()
      $block = $(@).closest('.block')
      _this.sidebarDropdownHidden($block)
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

  openDropdown: (blockOrName) ->
    $block = if _.isString(blockOrName) then @getBlock(blockOrName) else blockOrName

    $block.find('.edit-link').trigger('click')

    if not @isOpen()
      @setCollapseAfterUpdate($block)
      @toggleSidebar('open')

  setCollapseAfterUpdate: ($block) ->
    $block.addClass('collapse-after-update')
    $('.page-with-sidebar').addClass('with-overlay')

  sidebarDropdownHidden: ($block) ->
    if $block.hasClass('collapse-after-update')
      $block.removeClass('collapse-after-update')
      $('.page-with-sidebar').removeClass('with-overlay')
      @toggleSidebar('hide')

  triggerOpenSidebar: ->
    @sidebar
      .find('.js-sidebar-toggle')
      .trigger('click')

  toggleSidebar: (action = 'toggle') ->
    if action is 'toggle'
      @triggerOpenSidebar()

    if action is 'open'
      @triggerOpenSidebar() if not @isOpen()

    if action is 'hide'
      @triggerOpenSidebar() is @isOpen()

  isOpen: ->
    @sidebar.is('.right-sidebar-expanded')

  getBlock: (name) ->
    @sidebar.find(".block.#{name}")


