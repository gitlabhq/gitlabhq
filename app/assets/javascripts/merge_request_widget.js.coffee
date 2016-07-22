class @MergeRequestWidget
  # Initialize MergeRequestWidget behavior
  #
  #   check_enable           - Boolean, whether to check automerge status
  #   merge_check_url - String, URL to use to check automerge status
  #   ci_status_url        - String, URL to use to check CI status
  #

  constructor: (opts) ->
    @opts = opts || $('.js-merge-request-widget-options').data()
    console.log @opts
    @getMergeStatus() if @opts.check_status

    $('#modal_merge_info').modal(show: false)
    @firstCICheck = true
    @readyForCICheck = false
    @cancel = false
    clearInterval @fetchBuildStatusInterval

    @clearEventListeners()
    @addEventListeners()
    @getCIStatus(false)
    @pollCIStatus()
    notifyPermissions()

  clearEventListeners: ->
    $(document).off 'page:change.merge_request'
    $('.merge_when_build_succeeds').off 'click'

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
    $('.merge_when_build_succeeds').on 'click', (e) => @setMergeWhenBuildSucceeds e
    $('.accept_merge_request').on 'click', (e) => @acceptMergeRequest e

  mergeInProgress: (deleteSourceBranch = false)->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) ->
        if data.state == "merged"
          urlSuffix = if deleteSourceBranch then '?delete_source=true' else ''

          window.location.href = window.location.pathname + urlSuffix
        else if data.merge_error
          $('.mr-widget-body').html("<h4>" + data.merge_error + "</h4>")
        else
          callback = -> merge_request_widget.mergeInProgress(deleteSourceBranch)
          setTimeout(callback, 2000)
      dataType: 'json'

  getMergeStatus: ->
    $.get @opts.merge_check_url, (data) ->
      $('.mr-state-widget').replaceWith(data)

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

    $.getJSON @opts.ci_status_url, (data) =>
      return if @cancel
      @readyForCICheck = true

      if data.status is ''
        return

      if @firstCICheck || data.status isnt @opts.ci_status and data.status?
        @opts.ci_status = data.status
        @showCIStatus data.status
        if data.coverage
          @showCICoverage data.coverage

        # The first check should only update the UI, a notification
        # should only be displayed on status changes
        if showNotification and not @firstCICheck
          status = @ciLabelForStatus(data.status)

          if status is "preparing"
            title = @opts.ci_title.preparing
            status = status.charAt(0).toUpperCase() + status.slice(1)
            message = @opts.ci_message.preparing.replace('{{status}}', status)
          else
            title = @opts.ci_title.normal
            message = @opts.ci_message.normal.replace('{{status}}', status)

          title = title.replace('{{status}}', status)
          message = message.replace('{{sha}}', data.sha)
          message = message.replace('{{title}}', data.title)

          notify(
            title,
            message,
            @opts.gitlab_icon,
            ->
              @close()
              Turbolinks.visit _this.opts.builds_path
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

  setMergeWhenBuildSucceeds: (e) ->
    e.preventDefault()
    @whenBuildSucceedsInput ?= $("#merge_when_build_succeeds")
    @whenBuildSucceedsInput.val '1'


  acceptMergeRequest: (e) ->
    e.preventDefault()
    @acceptMergeRequestInput ?= $('.accept-mr-form :input')
    @acceptMergeButton ?= $('.js-merge-button')
    @acceptMergeRequestInput.disable()
    @acceptMergeButton.html '<i class="fa fa-spinner fa-spin"></i> Merge in progress'
    $.ajax
      dataType: 'json'
      method: 'POST'
      url: @opts.merge_path
    .done (res) ->
      console.log 'accept MR res', res
