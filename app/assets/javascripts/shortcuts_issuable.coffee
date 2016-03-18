#= require mousetrap
#= require shortcuts_navigation

class @ShortcutsIssuable extends ShortcutsNavigation
  constructor: (isMergeRequest) ->
    super()
    Mousetrap.bind('a', ->
      $('.block.assignee .edit-link').trigger('click')
      return false
    )
    Mousetrap.bind('m', ->
      $('.block.milestone .edit-link').trigger('click')
      return false
    )
    Mousetrap.bind('r', =>
      @replyWithSelectedText()
      return false
    )
    Mousetrap.bind('j', =>
      @prevIssue()
      return false
    )
    Mousetrap.bind('k', =>
      @nextIssue()
      return false
    )
    Mousetrap.bind('e', =>
      @editIssue()
      return false
    )


    if isMergeRequest
      @enabledHelp.push('.hidden-shortcut.merge_requests')
    else
      @enabledHelp.push('.hidden-shortcut.issues')

  prevIssue: ->
    $prevBtn = $('.prev-btn')
    if not $prevBtn.hasClass('disabled')
      Turbolinks.visit($prevBtn.attr('href'))

  nextIssue: ->
    $nextBtn = $('.next-btn')
    if not $nextBtn.hasClass('disabled')
      Turbolinks.visit($nextBtn.attr('href'))

  replyWithSelectedText: ->
    if window.getSelection
      selected = window.getSelection().toString()
      replyField = $('.js-main-target-form #note_note')

      return if selected.trim() == ""

      # Put a '>' character before each non-empty line in the selection
      quote = _.map selected.split("\n"), (val) ->
        "> #{val}\n" if val.trim() != ''

      # If replyField already has some content, add a newline before our quote
      separator = replyField.val().trim() != "" and "\n" or ''

      replyField.val (_, current) ->
        current + separator + quote.join('') + "\n"

      # Trigger autosave for the added text
      replyField.trigger('input')

      # Focus the input field
      replyField.focus()

  editIssue: ->
    $editBtn = $('.issuable-edit')
    Turbolinks.visit($editBtn.attr('href'))
