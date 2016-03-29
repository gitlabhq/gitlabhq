class @Compare
  constructor: (@opts) ->
    @source_loading = $ ".js-source-loading"
    @target_loading = $ ".js-target-loading"

    $('.js-compare-dropdown').each (i, dropdown) =>
      $dropdown = $(dropdown)

      $dropdown.glDropdown(
        selectable: true
        fieldName: $dropdown.data 'field-name'
        filterable: true
        id: (obj, $el) ->
          $el.data 'id'
        toggleLabel: (obj, $el) ->
          $el.text().trim()
        clicked: (e, el) =>
          if $dropdown.is '.js-target-branch'
            @getTargetHtml()
          else if $dropdown.is '.js-source-branch'
            @getSourceHtml()
          else if $dropdown.is '.js-target-project'
            @getTargetProject()
      )

    @initialState()

  initialState: ->
    @getSourceHtml()
    @getTargetHtml()

  getTargetProject: ->
    $.get @opts.targetProjectUrl,
      target_project_id:  $("input[name='merge_request[source_project]']").val()

  getSourceHtml: ->
    $.ajax(
      url: @opts.sourceBranchUrl
      data:
        ref: $("input[name='merge_request[source_branch]']").val()
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
        target_project_id: $("input[name='merge_request[target_project_id]']").val()
        ref: $("input[name='merge_request[target_branch]']").val()
      beforeSend: =>
        @target_loading.show()
        $(".mr_target_commit").html ""
      success: (html) =>
        @target_loading.hide()
        $(".mr_target_commit").html html
        $(".mr_target_commit .js-timeago").timeago()
    )
