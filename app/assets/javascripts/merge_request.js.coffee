#= require jquery
#= require bootstrap
#= require task_list

class @MergeRequest
  # Initialize MergeRequest behavior
  #
  # Options:
  #   action         - String, current controller action
  #   diffs_loaded   - Boolean, have diffs been pre-rendered server-side?
  #                    (default: true if `action` is 'diffs', otherwise false)
  #   commits_loaded - Boolean, have commits been pre-rendered server-side?
  #                    (default: false)
  #
  #   check_enable           - Boolean, whether to check automerge status
  #   url_to_automerge_check - String, URL to use to check automerge status
  #   current_status         - String, current automerge status
  #   ci_enable              - Boolean, whether a CI service is enabled
  #   url_to_ci_check        - String, URL to use to check CI status
  #
  constructor: (@opts) ->
    @initContextWidget()
    this.$el = $('.merge-request')

    @diffs_loaded = @opts.diffs_loaded or @opts.action == 'diffs'
    @commits_loaded = @opts.commits_loaded or false

    this.bindEvents()
    this.activateTabFromHash()

    this.initMergeWidget()
    this.$('.show-all-commits').on 'click', =>
      this.showAllCommits()

    modal = $('#modal_merge_info').modal(show: false)

    disableButtonIfEmptyField '#commit_message', '.accept_merge_request'

    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

    $('.merge-request-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')

  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  initContextWidget: ->
    $('.edit-merge_request.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#merge_request_assignee_id", ->
      $(this).submit()

  initMergeWidget: ->
    this.showState( @opts.current_status )

    if this.$('.automerge_widget').length and @opts.check_enable
      $.get @opts.url_to_automerge_check, (data) =>
        this.showState( data.merge_status )
      , 'json'

    if @opts.ci_enable
      $.get @opts.url_to_ci_check, (data) =>
        this.showCiState data.status
        if data.coverage
          this.showCiCoverage data.coverage
      , 'json'

  bindEvents: ->
    this.$('.merge-request-tabs a[data-toggle="tab"]').on 'shown.bs.tab', (e) =>
      $target = $(e.target)

      # Nothing else to be done if we're on the first tab
      return if $target.data('action') == 'notes'

      # Persist current tab selection via URL
      href = $target.attr('href')
      if href.substr(0,1) == '#'
        location.replace("#!#{href.substr(1)}")

      # Lazy-load diffs
      if $target.data('action') == 'diffs'
        this.loadDiff() unless @diffs_loaded
        $('.diff-header').trigger("sticky_kit:recalc")

    this.$('.accept_merge_request').on 'click', ->
      $('.automerge_widget.can_be_merged').hide()
      $('.merge-in-progress').show()

    this.$('.remove_source_branch').on 'click', ->
      $('.remove_source_branch_widget').hide()
      $('.remove_source_branch_in_progress').show()

    this.$(".remove_source_branch").on "ajax:success", (e, data, status, xhr) ->
      location.reload()

    this.$(".remove_source_branch").on "ajax:error", (e, data, status, xhr) =>
      this.$('.remove_source_branch_widget').hide()
      this.$('.remove_source_branch_in_progress').hide()
      this.$('.remove_source_branch_widget.failed').show()

  # Activates a tab section based on the `#!` URL hash
  #
  # If no hash value is present (i.e., on the initial page load), the first tab
  # is selected by default.
  #
  # ... unless the current controller action is `diffs`, in which case that tab
  # is selected instead. Fun, right?
  #
  # Note: We use a `#!` instead of a standard URL hash for two reasons:
  #
  # 1. Prevents the hash acting like an anchor and scrolling the page.
  # 2. Prevents mutating browser history.
  activateTabFromHash: ->
    # Correct the hash if we came here directly via the `/diffs` path
    if location.hash == '' and @opts.action == 'diffs'
      location.replace('#!diffs')

    if location.hash == ''
      this.$('.merge-request-tabs a[data-toggle="tab"]:first').tab('show')
    else if location.hash.substr(0,2) == '#!'
      this.$(".merge-request-tabs a[href='##{location.hash.substr(2)}']").tab("show")

  showState: (state) ->
    $('.automerge_widget').hide()
    $('.automerge_widget.' + state).show()

  showCiState: (state) ->
    $('.ci_widget').hide()
    allowed_states = ["failed", "canceled", "running", "pending", "success"]
    if state in allowed_states
      $('.ci_widget.ci-' + state).show()
      switch state
        when "failed", "canceled"
          @setMergeButtonClass('btn-danger')
        when "running", "pending"
          @setMergeButtonClass('btn-warning')
    else
      $('.ci_widget.ci-error').show()
      @setMergeButtonClass('btn-danger')

  showCiCoverage: (coverage) ->
    cov_html = $('<span>')
    cov_html.addClass('ci-coverage')
    cov_html.text('Coverage ' + coverage + '%')
    $('.ci_widget:visible').append(cov_html)

  loadDiff: (event) ->
    $.ajax
      type: 'GET'
      url: this.$('.merge-request-tabs .diffs-tab a').data('source') + ".json"
      beforeSend: =>
        this.$('.mr-loading-status .loading').show()
      complete: =>
        @diffs_loaded = true
        this.$('.mr-loading-status .loading').hide()
      success: (data) =>
        this.$(".diffs").html(data.html)
      dataType: 'json'

  showAllCommits: ->
    this.$('.first-commits').remove()
    this.$('.all-commits').removeClass 'hide'

  alreadyOrCannotBeMerged: ->
    this.$('.automerge_widget').hide()
    this.$('.merge-in-progress').hide()
    this.$('.automerge_widget.already_cannot_be_merged').show()

  setMergeButtonClass: (css_class) ->
    $('.accept_merge_request').removeClass("btn-create").addClass(css_class)

  mergeInProgress: ->
    $.ajax
      type: 'GET'
      url: $('.merge-request').data('url')
      success: (data) =>
        switch data.state
          when 'merged'
            location.reload()
          else
            setTimeout(merge_request.mergeInProgress, 3000)
      dataType: 'json'

  initTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.merge-request-details .js-task-list-container', @updateTaskList

  disableTaskList: ->
    $('.merge-request-details .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.merge-request-details .js-task-list-container'

  # TODO (rspeicher): Make the merge request description inline-editable like a
  # note so that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['merge_request'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-merge-request-update').attr('action')
      data: patchData
