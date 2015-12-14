class @Flash
  constructor: (message, type)->
    @flash = $(".flash-container")
    @flash.html("")

    innerDiv = $('<div/>',
      class: "flash-#{type}",
      text: message
    )
    innerDiv.appendTo(".flash-container")

    @flash.click -> $(@).fadeOut()
    @flash.show()

  pinTo: (selector) ->
    @flash.detach().appendTo(selector)
