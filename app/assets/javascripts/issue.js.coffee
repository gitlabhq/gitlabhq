#= require flash
#= require jquery.waitforimages
#= require task_list

class @Issue
  constructor: ->
    # Prevent duplicate event bindings
    @disableTaskList()
    @fixAffixScroll()
    if $('a.btn-close').length
      @initTaskList()
      @initIssueBtnEventListeners()

  fixAffixScroll: ->
    fixAffix = ->
      $discussion = $('.issuable-discussion')
      $sidebar = $('.issuable-sidebar')
      if $sidebar.hasClass('no-affix')
        $sidebar.removeClass(['affix-top','affix'])
      discussionHeight = $discussion.height()
      sidebarHeight = $sidebar.height()
      if sidebarHeight > discussionHeight
        $discussion.height(sidebarHeight + 50)
        $sidebar.addClass('no-affix')
    $(window).on('resize', fixAffix)
    fixAffix()

  initTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.detail-page-description .js-task-list-container', @updateTaskList

  initIssueBtnEventListeners: ->
    _this = @
    issueFailMessage = 'Unable to update this issue at this time.'
    $('a.btn-close, a.btn-reopen').on 'click', (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      $this = $(this)
      isClose = $this.hasClass('btn-close')
      shouldSubmit = $this.hasClass('btn-comment')
      if shouldSubmit
        _this.submitNoteForm($this.closest('form'))
      $this.prop('disabled', true)
      url = $this.attr('href')
      $.ajax
        type: 'PUT'
        url: url,
        error: (jqXHR, textStatus, errorThrown) ->
          issueStatus = if isClose then 'close' else 'open'
          new Flash(issueFailMessage, 'alert')
        success: (data, textStatus, jqXHR) ->
          if data.saved
            $(document).trigger('issuable:change');
            if isClose
              $('a.btn-close').addClass('hidden')
              $('a.btn-reopen').removeClass('hidden')
              $('div.status-box-closed').removeClass('hidden')
              $('div.status-box-open').addClass('hidden')
            else
              $('a.btn-reopen').addClass('hidden')
              $('a.btn-close').removeClass('hidden')
              $('div.status-box-closed').addClass('hidden')
              $('div.status-box-open').removeClass('hidden')
          else
            new Flash(issueFailMessage, 'alert')
          $this.prop('disabled', false)

  submitNoteForm: (form) =>
    noteText = form.find("textarea.js-note-text").val()
    if noteText.trim().length > 0
      form.submit()

  disableTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.detail-page-description .js-task-list-container'

  # TODO (rspeicher): Make the issue description inline-editable like a note so
  # that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['issue'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData
