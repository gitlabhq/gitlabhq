class @Flash
  hideFlash = -> $(@).fadeOut()

  constructor: (message, type = 'alert', parent = null)->
    if parent
      @flashContainer = parent.find('.flash-container')
    else
      @flashContainer = $('.flash-container-page')

    @flashContainer.html('')

    flash = $('<div/>',
      class: "flash-#{type}"
    )
    flash.on 'click', hideFlash

    textDiv = $('<div/>',
      class: 'flash-text',
      text: message
    )
    textDiv.appendTo(flash)

    if @flashContainer.parent().hasClass('content-wrapper')
      textDiv.addClass('container-fluid container-limited')

    flash.appendTo(@flashContainer)
    @flashContainer.show()

