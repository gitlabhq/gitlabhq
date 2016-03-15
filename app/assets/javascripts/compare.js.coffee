class @Compare
  constructor: (@opts) ->
    @source_loading = $ ".js-source-loading"
    @target_loading = $ ".js-target-loading"
    @source_branch = $ "#merge_request_source_branch"
    @target_branch = $ "#merge_request_target_branch"
    @target_project = $ "#merge_request_target_project_id"

    @initialState()
    @cleanBinding()
    @addBinding()

  cleanBinding: ->
    @source_branch.off "change"
    @target_branch.off "change"
    @target_project.off "change"

  addBinding: ->
    @source_branch.on "change", =>
      @getSourceHtml()
    @target_branch.on "change", =>
      @getTargetHtml()
    @target_project.on "change", =>
      @getTargetProject()

  initialState: ->
    @getSourceHtml()
    @getTargetHtml()

  getTargetProject: ->
    $.get @opts.targetProjectUrl,
      target_project_id:  @target_project.val()

  getSourceHtml: ->
    $.ajax(
      url: @opts.sourceBranchUrl
      data:
        ref: @source_branch.val()
      beforeSend: =>
        @source_loading.show()
        $(".mr_source_commit").html ""
      success: (html) =>
        @source_loading.hide()
        $(".mr_source_commit").html html
        $(".mr_source_commit .js-timeago").timeago()
    )

  getTargetHtml: ->
    $.ajax(
      url: @opts.targetBranchUrl
      data:
        target_project_id: @target_project.val()
        ref: @target_branch.val()
      beforeSend: =>
        @target_loading.show()
        $(".mr_target_commit").html ""
      success: (html) =>
        @target_loading.hide()
        $(".mr_target_commit").html html
        $(".mr_target_commit .js-timeago").timeago()
    )
