class MergeRequest
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

    disableButtonIfEmptyField '#merge_commit_message', '.accept_merge_request'


  # Local jQuery finder
  $: (selector) ->
    this.$el.find(selector)

  initContextWidget: ->
    $('.edit-merge_request.inline-update input[type="submit"]').hide()
    $(".issue-box .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issue-box .inline-update").on "change", "#merge_request_assignee_id", ->
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
      , 'json'

  bindEvents: ->
    this.$('.nav-tabs').on 'click', 'a', (event) =>
      a = $(event.currentTarget)

      href = a.attr('href')
      History.replaceState {path: href}, document.title, href

      event.preventDefault()

    this.$('.nav-tabs').on 'click', 'li', (event) =>
      this.activateTab($(event.currentTarget).data('action'))

    this.$('.accept_merge_request').on 'click', ->
      $('.automerge_widget.can_be_merged').hide()
      $('.merge-in-progress').show()

  activateTab: (action) ->
    this.$('.nav-tabs li').removeClass 'active'
    this.$('.tab-content').hide()
    switch action
      when 'diffs'
        this.$('.nav-tabs .diffs-tab').addClass 'active'
        this.loadDiff() unless @diffs_loaded
        this.$('.diffs').show()
      else
        this.$('.nav-tabs .notes-tab').addClass 'active'
        this.$('.notes').show()

  showState: (state) ->
    $('.automerge_widget').hide()
    $('.automerge_widget.' + state).show()

  showCiState: (state) ->
    $('.ci_widget').hide()
    $('.ci_widget.ci-' + state).show()

  loadDiff: (event) ->
    $.ajax
      type: 'GET'
      url: this.$('.nav-tabs .diffs-tab a').attr('href')
      beforeSend: =>
        this.$('.status').addClass 'loading'
      complete: =>
        @diffs_loaded = true
        this.$('.status').removeClass 'loading'
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

this.MergeRequest = MergeRequest
