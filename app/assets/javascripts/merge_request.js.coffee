#= require jquery
#= require bootstrap
#= require task_list

class @MergeRequest
  constructor: (@opts) ->
    @initContextWidget()
    this.$el = $('.merge-request')
    @diffs_loaded = if @opts.action == 'diffs' then true else false
    @commits_loaded = false

    this.activateTab(@opts.action)

    this.bindEvents()

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
    this.$('.merge-request-tabs').on 'click', 'li', (event) =>
      this.activateTab($(event.currentTarget).data('action'))

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

  activateTab: (action) ->
    this.$('.merge-request-tabs li').removeClass 'active'
    this.$('.tab-content').hide()
    switch action
      when 'diffs'
        this.$('.merge-request-tabs .diffs-tab').addClass 'active'
        this.loadDiff() unless @diffs_loaded
        this.$('.diffs').show()
        $(".diff-header").trigger("sticky_kit:recalc")
      when 'commits'
        this.$('.merge-request-tabs .commits-tab').addClass 'active'
        this.$('.commits').show()
      else
        this.$('.merge-request-tabs .notes-tab').addClass 'active'
        this.$('.notes').show()

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
      url: this.$('.merge-request-tabs .diffs-tab a').attr('href') + ".json"
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
