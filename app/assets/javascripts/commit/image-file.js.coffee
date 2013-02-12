class ImageFile

  # Width where images must fits in, for 2-up this gets divided by 2
  @availWidth = 900
  @viewModes = ['two-up', 'swipe']

  constructor: (@file) ->
    # Determine if old and new file has same dimensions, if not show 'two-up' view
    this.requestImageInfo $('.two-up.view .frame.deleted img', @file), (deletedWidth, deletedHeight) =>
      this.requestImageInfo $('.two-up.view .frame.added img', @file), (width, height) =>
        if width == deletedWidth && height == deletedHeight
          this.initViewModes()
        else
          this.initView('two-up')

  initViewModes: ->
    viewMode = ImageFile.viewModes[0]

    $('.view-modes', @file).removeClass 'hide'
    $('.view-modes-menu', @file).on 'click', 'li', (event) =>
      unless $(event.currentTarget).hasClass('active')
        this.activateViewMode(event.currentTarget.className)

    this.activateViewMode(viewMode)

  activateViewMode: (viewMode) ->
    $('.view-modes-menu li', @file)
      .removeClass('active')
      .filter(".#{viewMode}").addClass 'active'
    $(".view:visible:not(.#{viewMode})", @file).fadeOut 200, =>
      $(".view.#{viewMode}", @file).fadeIn(200)
      this.initView viewMode

  initView: (viewMode) ->
    this.views[viewMode].call(this)

  prepareFrames = (view) ->
    maxWidth = 0
    maxHeight = 0
    $('.frame', view).each (index, frame) =>
      width = $(frame).width()
      height = $(frame).height()
      maxWidth = if width > maxWidth then width else maxWidth
      maxHeight = if height > maxHeight then height else maxHeight
    .css
      width: maxWidth
      height: maxHeight
    
    [maxWidth, maxHeight]

  views: 
    'two-up': ->
      $('.two-up.view .wrap', @file).each (index, wrap) =>
        $('img', wrap).each ->
          currentWidth = $(this).width()
          if currentWidth > ImageFile.availWidth / 2
            $(this).width ImageFile.availWidth / 2

        this.requestImageInfo $('img', wrap), (width, height) ->
          $('.image-info .meta-width', wrap).text "#{width}px"
          $('.image-info .meta-height', wrap).text "#{height}px"
          $('.image-info', wrap).removeClass('hide')

    'swipe': ->
      maxWidth = 0
      maxHeight = 0

      $('.swipe.view', @file).each (index, view) =>

        [maxWidth, maxHeight] = prepareFrames(view)

        $('.swipe-frame', view).css
          width: maxWidth + 16
          height: maxHeight + 28

        $('.swipe-wrap', view).css
          width: maxWidth + 1
          height: maxHeight + 2

        $('.swipe-bar', view).css
          left: 0
        .draggable
          axis: 'x'
          containment: 'parent'
          drag: (event) ->
            $('.swipe-wrap', view).width (maxWidth + 1) - $(this).position().left
          stop: (event) ->
            $('.swipe-wrap', view).width (maxWidth + 1) - $(this).position().left

    'onion-skin': ->
      maxWidth = 0
      maxHeight = 0

      dragTrackWidth = $('.drag-track', @file).width() - $('.dragger', @file).width()

      $('.onion-skin.view', @file).each (index, view) =>

        [maxWidth, maxHeight] = prepareFrames(view)

        $('.onion-skin-frame', view).css
          width: maxWidth + 16
          height: maxHeight + 28

        $('.swipe-wrap', view).css
          width: maxWidth + 1
          height: maxHeight + 2
        
        $('.dragger', view).css
          left: dragTrackWidth
        .draggable
          axis: 'x'
          containment: 'parent'
          drag: (event) ->
            $('.frame.added', view).css('opacity', $(this).position().left / dragTrackWidth)
          stop: (event) ->
            $('.frame.added', view).css('opacity', $(this).position().left / dragTrackWidth)
        
      

  requestImageInfo: (img, callback) ->
    domImg = img.get(0)
    if domImg.complete
      callback.call(this, domImg.naturalWidth, domImg.naturalHeight)
    else
      img.on 'load', =>
        callback.call(this, domImg.naturalWidth, domImg.naturalHeight)

this.ImageFile = ImageFile