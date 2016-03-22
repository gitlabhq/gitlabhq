class @IssuableContext
  constructor: ->
    @initParticipants()

    new UsersSelect()
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

    $(".right-sidebar").niceScroll()

  initParticipants: ->
    _this = @
    $(document).on "click", ".js-participants-more", @toggleHiddenParticipants

    $(".js-participants-author").each (i) ->
      if i >= _this.PARTICIPANTS_ROW_COUNT
        $(@)
          .addClass "js-participants-hidden"
          .hide()

  toggleHiddenParticipants: (e) ->
    e.preventDefault()

    currentText = $(this).text().trim()
    lessText = $(this).data("less-text")
    originalText = $(this).data("original-text")

    if currentText is originalText
      $(this).text(lessText)
    else
      $(this).text(originalText)

    $(".js-participants-hidden").toggle()
