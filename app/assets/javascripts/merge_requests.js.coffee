
#
# * Filter merge requests
#
@merge_requestsPage = ->
  $("#assignee_id").chosen()
  $("#milestone_id").chosen()
  $("#milestone_id, #assignee_id").on "change", ->
    $(this).closest("form").submit()

@MergeRequest =
  diffs_loaded: false
  commits_loaded: false
  opts: false
  init: (opts) ->
    self = @
    self.opts = opts
    self.initTabs()
    self.initMergeWidget()
    $(".mr_show_all_commits").bind "click", ->
      self.showAllCommits()


  initMergeWidget: ->
    self = this
    self.showState self.opts.current_state
    if $(".automerge_widget").length and self.opts.check_enable
      $.get self.opts.url_to_automerge_check, ((data) ->
        self.showState data.state
      ), "json"
    if self.opts.ci_enable
      $.get self.opts.url_to_ci_check, ((data) ->
        self.showCiState data.status
      ), "json"

  initTabs: ->
    $(".mr_nav_tabs a").on "click", ->
      $(".mr_nav_tabs a").parent().removeClass "active"
      $(this).parent().addClass "active"

    current_tab = undefined
    if @opts.action is "diffs"
      current_tab = $(".mr_nav_tabs .merge-diffs-tab")
    else
      current_tab = $(".mr_nav_tabs .merge-notes-tab")
    current_tab.parent().addClass "active"
    @initNotesTab()
    @initDiffTab()

  initNotesTab: ->
    $(".mr_nav_tabs a.merge-notes-tab").on "click", (e) ->
      $(".merge-request-diffs").hide()
      $(".merge_request_notes").show()
      mr_path = $(".merge-notes-tab").attr("data-url")
      history.pushState
        path: mr_path
      , "", mr_path
      e.preventDefault()


  initDiffTab: ->
    $(".mr_nav_tabs a.merge-diffs-tab").on "click", (e) ->
      MergeRequest.loadDiff()  unless MergeRequest.diffs_loaded
      $(".merge_request_notes").hide()
      $(".merge-request-diffs").show()
      mr_diff_path = $(".merge-diffs-tab").attr("data-url")
      history.pushState
        path: mr_diff_path
      , "", mr_diff_path
      e.preventDefault()


  showState: (state) ->
    $(".automerge_widget").hide()
    $(".automerge_widget." + state).show()

  showCiState: (state) ->
    $(".ci_widget").hide()
    $(".ci_widget.ci-" + state).show()

  loadDiff: ->
    $(".dashboard-loader").show()
    $.ajax
      type: "GET"
      url: $(".merge-diffs-tab").attr("data-url")
      beforeSend: ->
        $(".status").addClass "loading"

      complete: ->
        MergeRequest.diffs_loaded = true
        $(".merge_request_notes").hide()
        $(".status").removeClass "loading"

      dataType: "script"


  showAllCommits: ->
    $(".first_mr_commits").remove()
    $(".all_mr_commits").removeClass "hide"

  already_cannot_be_merged: ->
    $(".automerge_widget").hide()
    $(".merge_in_progress").hide()
    $(".automerge_widget.already_cannot_be_merged").show()
