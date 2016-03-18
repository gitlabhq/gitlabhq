# MarkdownPreview
#
# Handles toggling the "Write" and "Preview" tab clicks, rendering the preview,
# and showing a warning when more than `x` users are referenced.
#
class @MarkdownPreview
  # Minimum number of users referenced before triggering a warning
  referenceThreshold: 10
  ajaxCache: {}

  showPreview: (form) ->
    preview = form.find('.js-md-preview')
    mdText  = form.find('textarea.markdown-area').val()

    if mdText.trim().length == 0
      preview.text('Nothing to preview.')
      @hideReferencedUsers(form)
    else
      preview.text('Loading...')
      @renderMarkdown mdText, (response) =>
        preview.html(response.body)
        preview.syntaxHighlight()
        @renderReferencedUsers(response.references.users, form)

  renderMarkdown: (text, success) ->
    return unless window.markdown_preview_path

    return success(@ajaxCache.response) if text == @ajaxCache.text

    $.ajax
      type: 'POST'
      url: window.markdown_preview_path
      data: { text: text }
      dataType: 'json'
      success: (response) =>
        @ajaxCache = text: text, response: response
        success(response)

  hideReferencedUsers: (form) ->
    referencedUsers = form.find('.referenced-users')
    referencedUsers.hide()

  renderReferencedUsers: (users, form) ->
    referencedUsers = form.find('.referenced-users')

    if referencedUsers.length
      if users.length >= @referenceThreshold
        referencedUsers.show()
        referencedUsers.find('.js-referenced-users-count').text(users.length)
      else
        referencedUsers.hide()

markdownPreview = new MarkdownPreview()

previewButtonSelector = '.js-md-preview-button'
writeButtonSelector   = '.js-md-write-button'
lastTextareaPreviewed = null

$.fn.setupMarkdownPreview = ->
  $form = $(this)

  form_textarea = $form.find('textarea.markdown-area')

  form_textarea.on 'input', -> markdownPreview.hideReferencedUsers($form)
  form_textarea.on 'blur',  -> markdownPreview.showPreview($form)

$(document).on 'markdown-preview:show', (e, $form) ->
  return unless $form

  lastTextareaPreviewed = $form.find('textarea.markdown-area')

  # toggle tabs
  $form.find(writeButtonSelector).parent().removeClass('active')
  $form.find(previewButtonSelector).parent().addClass('active')

  # toggle content
  $form.find('.md-write-holder').hide()
  $form.find('.md-preview-holder').show()

  markdownPreview.showPreview($form)

$(document).on 'markdown-preview:hide', (e, $form) ->
  return unless $form

  lastTextareaPreviewed = null

  # toggle tabs
  $form.find(writeButtonSelector).parent().addClass('active')
  $form.find(previewButtonSelector).parent().removeClass('active')

  # toggle content
  $form.find('.md-write-holder').show()
  $form.find('textarea.markdown-area').focus()
  $form.find('.md-preview-holder').hide()

$(document).on 'markdown-preview:toggle', (e, keyboardEvent) ->
  $target = $(keyboardEvent.target)

  if $target.is('textarea.markdown-area')
    $(document).triggerHandler('markdown-preview:show', [$target.closest('form')])
    keyboardEvent.preventDefault()
  else if lastTextareaPreviewed
    $target = lastTextareaPreviewed
    $(document).triggerHandler('markdown-preview:hide', [$target.closest('form')])
    keyboardEvent.preventDefault()

$(document).on 'click', previewButtonSelector, (e) ->
  e.preventDefault()

  $form = $(this).closest('form')

  $(document).triggerHandler('markdown-preview:show', [$form])

$(document).on 'click', writeButtonSelector, (e) ->
  e.preventDefault()

  $form = $(this).closest('form')

  $(document).triggerHandler('markdown-preview:hide', [$form])
