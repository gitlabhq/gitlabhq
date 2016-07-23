class @MergeRequestWidget
  # Initialize MergeRequestWidget behavior
  #
  #   checkEnable           - Boolean, whether to check automerge status
  #   mergeCheckUrl - String, URL to use to check automerge status
  #   ciStatusUrl        - String, URL to use to check CI status
  #

  constructor: (opts) ->
    @mergeRequestWidget = $('.mr-state-widget')
    @mergeRequestWidgetBody = $('.mr-widget-body')

    @opts = opts || $('.js-merge-request-widget-options').data()

    @getInputs()
    @getButtons true

    @getMergeStatus() if @opts.checkStatus

    $('#modal_merge_info').modal(show: false)
    @firstCICheck = true
    @readyForCICheck = false
    @cancel = false
    clearInterval @fetchBuildStatusInterval

    @clearButtonEventListeners()
    @clearEventListeners()
    @addButtonEventListeners()
    @addEventListeners()
    @getCIStatus(false)
    @pollCIStatus()
    notifyPermissions()

  getInputs: ->
    @acceptMergeRequestInput = $('.accept-mr-form :input')
    @commitMessageInput = $('textarea[name=commit_message]')
    @mergeWhenSucceedsInput = $('input[name=merge_when_build_succeeds]')
    @removeSourceBranchInput = $('input[name=should_remove_source_branch]')
    @shaInput = $('input[name=sha]')
    @utfInput = $('input[name=utf8]')

    @authenticityTokenInput = $('input[name=authenticity_token]', @mergeRequestWidget)

  getButtons: (skipListeners) ->
    @dynamicMergeButton = $('.js-merge-button')
    @acceptMergeRequestButton = $('.accept_merge_request')
    @cancelMergeOnSuccessButton = $('.js-cancel-automatic-merge')
    @mergeWhenSucceedsButton = $('.merge_when_build_succeeds')
    @removeSourceBranchButton = $('.remove_source_branch')
    @addButtonEventListeners() unless skipListeners

  clearEventListeners: ->
    $(document).off 'page:change.merge_request'

  clearButtonEventListeners: ->
    @mergeWhenSucceedsButton.off 'click'
    @acceptMergeRequestButton.off 'click'
    @cancelMergeOnSuccessButton.off 'click'
    @removeSourceBranchButton.off 'click'

  cancelPolling: ->
    @cancel = true

  addEventListeners: ->
    allowedPages = ['show', 'commits', 'builds', 'changes']
    $(document).on 'page:change.merge_request', =>
      page = $('body').data('page').split(':').last()
      if allowedPages.indexOf(page) < 0
        clearInterval @fetchBuildStatusInterval
        @cancelPolling()
        @clearEventListeners()

  addButtonEventListeners: ->
    @mergeWhenSucceedsButton.on 'click', (e) =>
      @mergeWhenSucceedsInput.val '1'
      @acceptMergeRequest e
    @acceptMergeRequestButton.on 'click', (e) => @acceptMergeRequest e
    @cancelMergeOnSuccessButton.on 'click', (e) => @cancelMergeOnSuccess e
    @removeSourceBranchButton.on 'click', (e) =>
      @mergeWhenSucceedsInput.val '1'
      @acceptMergeRequest e, @removeSourceBranchButton.data 'url'

  mergeInProgress: (deleteSourceBranch = false) ->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      dataType: 'json'
      success: (data) =>
        if data.state == "merged"
          urlSuffix = if deleteSourceBranch then '?delete_source=true' else ''

          window.location.href = window.location.pathname + urlSuffix
        else if data.merge_error
          @mergeRequestWidgetBody.html("<h4>" + data.merge_error + "</h4>")
        else
          setTimeout =>
            @mergeInProgress(deleteSourceBranch)
          , 2000

  getMergeStatus: ->
    $.get @opts.mergeCheckUrl, (data) =>
      @mergeRequestWidget.replaceWith(data)
      @getButtons()
      @getInputs()

  ciLabelForStatus: (status) ->
    switch status
      when 'success'
        'passed'
      when 'success_with_warnings'
        'passed with warnings'
      else
        status

  pollCIStatus: ->
    @fetchBuildStatusInterval = setInterval ( =>
      return if not @readyForCICheck

      @getCIStatus(true)

      @readyForCICheck = false
    ), 10000

  getCIStatus: (showNotification) ->
    _this = @
    $('.ci-widget-fetching').show()

    $.getJSON @opts.ciStatusUrl, (data) =>
      return if @cancel
      @readyForCICheck = true

      if data.status is ''
        return

      if @firstCICheck || data.status isnt @opts.ciStatus and data.status?
        @opts.ciStatus = data.status
        @showCIStatus data.status
        if data.coverage
          @showCICoverage data.coverage

        # The first check should only update the UI, a notification
        # should only be displayed on status changes
        if showNotification and not @firstCICheck
          status = @ciLabelForStatus(data.status)

          if status is "preparing"
            title = @opts.ciTitle.preparing
            status = status.charAt(0).toUpperCase() + status.slice(1)
            message = @opts.ciMessage.preparing.replace('{{status}}', status)
          else
            title = @opts.ciTitle.normal
            message = @opts.ciMessage.normal.replace('{{status}}', status)

          title = title.replace('{{status}}', status)
          message = message.replace('{{sha}}', data.sha)
          message = message.replace('{{title}}', data.title)

          notify(
            title,
            message,
            @opts.gitlabIcon,
            ->
              @close()
              Turbolinks.visit _this.opts.buildsPath
          )
        @firstCICheck = false

  showCIStatus: (state) ->
    return if not state?
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success", "success_with_warnings", "skipped", "not_found"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled", "not_found"
          @setMergeButtonClass('btn-danger')
        when "running"
          @setMergeButtonClass('btn-warning')
        when "success", "success_with_warnings"
          @setMergeButtonClass('btn-create')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCICoverage: (coverage) ->
    text = 'Coverage ' + coverage + '%'
    $('.ci_widget:visible .ci-coverage').text(text)

  setMergeButtonClass: (css_class) ->
    $('.js-merge-button,.accept-action .dropdown-toggle')
      .removeClass('btn-danger btn-warning btn-create')
      .addClass(css_class)

  acceptMergeRequest: (e, url) ->
    e.preventDefault() if e
    @acceptMergeRequestInput.disable()
    @dynamicMergeButton.html '<i class="fa fa-spinner fa-spin"></i> Merge in progress'
    $.ajax
      method: 'POST'
      url: url || @opts.mergePath
      data:
        utf8: @utfInput.val()
        authenticity_token: @authenticityTokenInput.val()
        sha: @shaInput.val()
        commit_message: @commitMessageInput.val()
        merge_when_build_succeeds: @mergeWhenSucceedsInput.val()
        should_remove_source_branch: @removeSourceBranchInput.val() if @removeSourceBranchInput.is ':checked'
    .done (res) =>
      console.log res, 'res'
      if res.merge_in_progress?
        @mergeInProgress res.merge_in_progress
      else
        @mergeRequestWidgetBody.html res
        @getButtons()
        @getInputs()

  cancelMergeOnSuccess: (e) ->
    e.preventDefault() if e
    $.ajax
      method: 'POST'
      url: @opts.cancelMergeOnSuccessPath
    .done (res) =>
      @mergeRequestWidgetBody.html res
      @getButtons()
      @getInputs()
