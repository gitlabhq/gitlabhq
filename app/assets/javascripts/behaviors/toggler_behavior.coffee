$ ->
  $("body").on "click", ".js-toggler-target", ->
    container = $(@).closest(".js-toggler-container")

    container.toggleClass("on")
