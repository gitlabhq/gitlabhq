class @Flash
  constructor: (message, type = 'alert')->
    @flash = $(".flash-container")
    @flash.html("")

    innerDiv = $('<div/>',
      class: "flash-#{type}"
    )
    innerDiv.appendTo(".flash-container")

    textDiv = $("<div/>",
      class: "flash-text",
      text: message
    )
    textDiv.appendTo(innerDiv)

    if @flash.parent().hasClass('content-wrapper')
      textDiv.addClass('container-fluid container-limited')

    @flash.click -> $(@).fadeOut()
    @flash.show()

  pinTo: (selector) ->
    @flash.detach().appendTo(selector)
