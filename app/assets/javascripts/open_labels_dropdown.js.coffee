@openLabelsDropdown =
  init: ->
    $(".labels-display-none").on "click",  ->
      $(this).select2("open")

$ ->
  openLabelsDropdown.init()
