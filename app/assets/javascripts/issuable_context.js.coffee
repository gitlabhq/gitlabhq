#= require jquery.waitforimages

class @IssuableContext
  constructor: ->
    new UsersSelect()
    new LabelsSelect()
    $('select.select2').select2({width: 'resolve', dropdownAutoWidth: true})

    $(".issuable-sidebar .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issuable-sidebar .inline-update").on "change", ".js-assignee", ->
      $(this).submit()

    $(document).on "click",".edit-link", (e) ->
      block = $(@).parents('.block')
      block.find('.selectbox').show()
      block.find('.value').hide()
      block.find('.js-select2').select2("open")

      $(@).parents('.dropdown')
        .addClass("open")
        .trigger('shown.bs.dropdown')

    $(".right-sidebar").niceScroll()
