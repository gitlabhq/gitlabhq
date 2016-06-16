class @Sidebar
  constructor: (currentUser) ->
    @sidebar = $('aside')

    @addEventListeners()

  addEventListeners: ->
    @sidebar.on('click', '.sidebar-collapsed-icon', @, @sidebarCollapseClicked)
    $('.dropdown').on('hidden.gl.dropdown', @, @onSidebarDropdownHidden)
    $('.dropdown').on('loading.gl.dropdown', @sidebarDropdownLoading)
    $('.dropdown').on('loaded.gl.dropdown', @sidebarDropdownLoaded)


    $(document)
      .off 'click', '.js-sidebar-toggle'
      .on 'click', '.js-sidebar-toggle', (e, triggered) ->
        e.preventDefault()
        $this = $(this)
        $thisIcon = $this.find 'i'
        $allGutterToggleIcons = $('.js-sidebar-toggle i')
        if $thisIcon.hasClass('fa-angle-double-right')
          $allGutterToggleIcons
            .removeClass('fa-angle-double-right')
            .addClass('fa-angle-double-left')
          $('aside.right-sidebar')
            .removeClass('right-sidebar-expanded')
            .addClass('right-sidebar-collapsed')
          $('.page-with-sidebar')
            .removeClass('right-sidebar-expanded')
            .addClass('right-sidebar-collapsed')
        else
          $allGutterToggleIcons
            .removeClass('fa-angle-double-left')
            .addClass('fa-angle-double-right')
          $('aside.right-sidebar')
            .removeClass('right-sidebar-collapsed')
            .addClass('right-sidebar-expanded')
          $('.page-with-sidebar')
            .removeClass('right-sidebar-collapsed')
            .addClass('right-sidebar-expanded')
        if not triggered
          $.cookie("collapsed_gutter",
            $('.right-sidebar')
              .hasClass('right-sidebar-collapsed'), { path: '/' })


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
    sidebar = e.data
    e.preventDefault()
    $block = $(@).closest('.block')
    sidebar.openDropdown($block);

  openDropdown: (blockOrName) ->
    $block = if _.isString(blockOrName) then @getBlock(blockOrName) else blockOrName

    $block.find('.edit-link').trigger('click')

    if not @isOpen()
      @setCollapseAfterUpdate($block)
      @toggleSidebar('open')

  setCollapseAfterUpdate: ($block) ->
    $block.addClass('collapse-after-update')
    $('.page-with-sidebar').addClass('with-overlay')

  onSidebarDropdownHidden: (e) ->
    sidebar = e.data
    e.preventDefault()
    $block = $(@).closest('.block')
    sidebar.sidebarDropdownHidden($block)

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
      @triggerOpenSidebar() if @isOpen()

  isOpen: ->
    @sidebar.is('.right-sidebar-expanded')

  getBlock: (name) ->
    @sidebar.find(".block.#{name}")


