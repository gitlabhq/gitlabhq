class @Flash
  constructor: (message, type)->
    flash = $(".flash-container")
    flash.html("")

    $('<div/>',
      class: "flash-#{type}",
      text: message
    ).appendTo(".flash-container")

    flash.click -> $(@).fadeOut()
    flash.show()
