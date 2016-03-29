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
    $.ajax(
      url: @opts.targetProjectUrl
      data:
        target_project_id:  $("input[name='merge_request[target_project_id]']").val()
      beforeSend: ->
        $('.mr_target_commit').empty()
      success: (html) ->
        $('.js-target-branch-dropdown .dropdown-content').html html
    )

  getSourceHtml: ->
    @sendAjax(@opts.sourceBranchUrl, @source_loading, '.mr_source_commit',
      ref: $("input[name='merge_request[source_branch]']").val()
    )

  getTargetHtml: ->
    @sendAjax(@opts.targetBranchUrl, @target_loading, '.mr_target_commit',
      target_project_id: $("input[name='merge_request[target_project_id]']").val()
      ref: $("input[name='merge_request[target_branch]']").val()
    )

  sendAjax: (url, loading, target, data) ->
    $target = $(target)

    $.ajax(
      url: url
      data: data
      beforeSend: ->
        loading.show()
        $target.empty()
      success: (html) ->
        loading.hide()
        $target.html html
        $('.js-timeago', $target).timeago()
    )
