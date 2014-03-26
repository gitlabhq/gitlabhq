$ ->
  $("body").on "click", ".js-details-target", ->
    container = $(@).closest(".js-details-container")
    container.toggleClass("open")

  # Show details content. Hides link after click.
  #
  # %div
  #   %a.js-details-expand
  #   %div.js-details-content
  #
  $("body").on "click", ".js-details-expand", (e) ->
    $(@).next('.js-details-content').removeClass("hide")
    $(@).hide()
    e.preventDefault()
