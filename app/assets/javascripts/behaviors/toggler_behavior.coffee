$ ->
  $("body").on "click", ".js-toggler-target", ->
    container = $(@).closest(".js-toggler-container")

    container.toggleClass("on")

  $("body").on "click", ".js-toggle-visibility-link", (e) ->
    $(@).find('i').
      toggleClass('icon-chevron-down').
      toggleClass('icon-chevron-up')
    container = $(".js-toggle-visibility-container")
    container.toggleClass("hide")
    e.preventDefault()

  $("body").on "click", ".js-toggle-button", (e) ->
    $(@).closest(".js-toggle-container").find(".js-toggle-content").toggle()
    e.preventDefault()
