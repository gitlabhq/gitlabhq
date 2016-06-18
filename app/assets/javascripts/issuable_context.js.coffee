class @IssuableContext
  constructor: (currentUser) ->
    @initParticipants()
    new UsersSelect(currentUser)
    $('select.select2').select2({width: 'resolve', dropdownAutoWidth: true})

    $(".issuable-sidebar .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issuable-sidebar .inline-update").on "change", ".js-assignee", ->
      $(this).submit()

    $(document)
      .off 'click', '.issuable-sidebar .dropdown-content a'
      .on 'click', '.issuable-sidebar .dropdown-content a', (e) ->
        e.preventDefault()

    $(document)
      .off 'click', '.edit-link'
      .on 'click', '.edit-link', (e) ->
        e.preventDefault()

        $block = $(@).parents('.block')
        $selectbox = $block.find('.selectbox')
        if $selectbox.is(':visible')
          $selectbox.hide()
          $block.find('.value').show()
        else
          $selectbox.show()
          $block.find('.value').hide()

        if $selectbox.is(':visible')
          setTimeout ->
            $block.find('.dropdown-menu-toggle').trigger 'click'
          , 0

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
