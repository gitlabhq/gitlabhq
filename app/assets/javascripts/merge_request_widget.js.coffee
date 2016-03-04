class @MergeRequestWidget
  # Initialize MergeRequestWidget behavior
  #
  #   check_enable           - Boolean, whether to check automerge status
  #   url_to_automerge_check - String, URL to use to check automerge status
  #   url_to_ci_check        - String, URL to use to check CI status
  #

  constructor: (@opts) ->
    @first = true
    modal = $('#modal_merge_info').modal(show: false)
    @getBuildStatus()
    @readyForCICheck = true
    # clear the build poller

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
          setTimeout(callback, 2000)
      dataType: 'json'

  getMergeStatus: ->
    $.get @opts.url_to_automerge_check, (data) ->
      $('.mr-state-widget').replaceWith(data)

  ciLabelForStatus: (status) ->
    if status == 'success'
      'passed'
    else
      status

  getBuildStatus: ->
    urlToCiCheck = @opts.url_to_ci_check
    _this = @
    @fetchBuildStatusInterval = setInterval (->
      if not _this.readyForCICheck
        return;
      $.getJSON urlToCiCheck, (data) ->
        _this.readyForCICheck = true
        if _this.first
          _this.first = false
          _this.opts.current_status = data.status
        if data.status isnt _this.opts.current_status
          notify("Build #{_this.ciLabelForStatus(data.status)}",
            _this.opts.ci_message.replace('{{status}}',
              _this.ciLabelForStatus(data.status)), 
            _this.opts.gitlab_icon)
          setTimeout (->
            Turbolinks.visit(location.href)
            return
          ), 2000
          _this.opts.current_status = data.status
        return
      _this.readyForCICheck = false
      return

    ), 5000

  getCiStatus: ->
    $.get @opts.url_to_ci_check, (data) =>
      this.showCiState data.status
      if data.coverage
        this.showCiCoverage data.coverage
    , 'json'

  showCiState: (state) ->
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success", "skipped", "not_found"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled", "not_found"
          @setMergeButtonClass('btn-danger')
        when "running", "pending"
          @setMergeButtonClass('btn-warning')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCiCoverage: (coverage) ->
    text = 'Coverage ' + coverage + '%'
    $('.ci_widget:visible .ci-coverage').text(text)

  setMergeButtonClass: (css_class) ->
    $('.accept_merge_request').removeClass("btn-create").addClass(css_class)
