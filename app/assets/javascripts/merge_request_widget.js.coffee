class @MergeRequestWidget
  # Initialize MergeRequestWidget behavior
  #
  #   check_enable           - Boolean, whether to check automerge status
  #   merge_check_url - String, URL to use to check automerge status
  #   ci_status_url        - String, URL to use to check CI status
  #

  constructor: (@opts) ->
    $('#modal_merge_info').modal(show: false)
    @firstCICheck = true
    @readyForCICheck = true
    clearInterval @fetchBuildStatusInterval

    @clearEventListeners()
    @addEventListeners()
    @pollCIStatus()
    notifyPermissions()

  clearEventListeners: ->
    $(document).off 'page:change.merge_request'

  addEventListeners: ->
    $(document).on 'page:change.merge_request', =>
      if $('body').data('page') isnt 'projects:merge_requests:show'
        clearInterval @fetchBuildStatusInterval
        @clearEventListeners()

  mergeInProgress: (deleteSourceBranch = false)->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) =>
        if data.state == "merged"
          urlSuffix = if deleteSourceBranch then '?delete_source=true' else ''

          window.location.href = window.location.pathname + urlSuffix
        else if data.merge_error
          $('.mr-widget-body').html("<h4>" + data.merge_error + "</h4>")
        else
          callback = -> merge_request_widget.mergeInProgress(deleteSourceBranch)
          setTimeout(callback, 1000)
      dataType: 'json'

  rebaseInProgress: ->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) =>
        if data["rebase_in_progress?"]
          setTimeout(merge_request_widget.rebaseInProgress, 1000)
        else
          location.reload()
      dataType: 'json'

  getMergeStatus: ->
    $.get @opts.merge_check_url, (data) ->
      $('.mr-state-widget').replaceWith(data)

  ciLabelForStatus: (status) ->
    if status is 'success'
      'passed'
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
      @readyForCICheck = true

      if @firstCICheck
        @firstCICheck = false
        @opts.ci_status = data.status

      if @opts.ci_status is ''
        @opts.ci_status = data.status
        return

      if data.status isnt @opts.ci_status and data.status?
        @showCIStatus data.status
        if data.coverage
          @showCICoverage data.coverage

        if showNotification
          status = @ciLabelForStatus(data.status)

          if status is "preparing"
            title = @opts.ci_title.preparing
            status = status.charAt(0).toUpperCase() + status.slice(1);
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

        @opts.ci_status = data.status

  showCIStatus: (state) ->
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success", "skipped", "not_found"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled", "not_found"
          @setMergeButtonClass('btn-danger')
        when "running", "pending"
          @setMergeButtonClass('btn-warning')
        when "success"
          @setMergeButtonClass('btn-create')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCICoverage: (coverage) ->
    text = 'Coverage ' + coverage + '%'
    $('.ci_widget:visible .ci-coverage').text(text)

  setMergeButtonClass: (css_class) ->
    $('.accept_merge_request')
      .removeClass('btn-danger btn-warning btn-create')
      .addClass(css_class)
