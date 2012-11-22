$ ->
  $("body").on "click", ".js-details-target", ->
    container = $(@).closest(".js-details-container")

    container.toggleClass("open")
