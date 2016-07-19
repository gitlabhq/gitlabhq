class @Milestone
  @updateIssue: (li, issue_url, data) ->
    $.ajax
      type: "PUT"
      url: issue_url
      data: data
      success: (_data) =>
        @successCallback(_data, li)
      error: (data) ->
        new Flash("Issue update failed", 'alert')
      dataType: "json"

  @sortIssues: (data) ->
    sort_issues_url = location.href + "/sort_issues"

    $.ajax
      type: "PUT"
      url: sort_issues_url
      data: data
      success: (_data) =>
        @successCallback(_data)
      error: ->
        new Flash("Issues update failed", 'alert')
      dataType: "json"

  @sortMergeRequests: (data) ->
    sort_mr_url = location.href + "/sort_merge_requests"

    $.ajax
      type: "PUT"
      url: sort_mr_url
      data: data
      success: (_data) =>
        @successCallback(_data)
      error: (data) ->
        new Flash("Issue update failed", 'alert')
      dataType: "json"

  @updateMergeRequest: (li, merge_request_url, data) ->
    $.ajax
      type: "PUT"
      url: merge_request_url
      data: data
      success: (_data) =>
        @successCallback(_data, li)
      error: (data) ->
        new Flash("Issue update failed", 'alert')
      dataType: "json"

  @successCallback: (data, element) =>
    if data.assignee
      img_tag = $('<img/>')
      img_tag.attr('src', data.assignee.avatar_url)
      img_tag.addClass('avatar s16')
      $(element).find('.assignee-icon').html(img_tag)
    else
      $(element).find('.assignee-icon').html('')

    $(element).effect 'highlight'

  constructor: ->
    oldMouseStart = $.ui.sortable.prototype._mouseStart
    $.ui.sortable.prototype._mouseStart = (event, overrideHandle, noActivation) ->
      this._trigger "beforeStart", event, this._uiHash()
      oldMouseStart.apply this, [event, overrideHandle, noActivation]

    @bindIssuesSorting()
    @bindMergeRequestSorting()
    @bindTabsSwitching()

  bindIssuesSorting: ->
    $("#issues-list-unassigned, #issues-list-ongoing, #issues-list-closed").sortable(
      connectWith: ".issues-sortable-list",
      dropOnEmpty: true,
      items: "li:not(.ui-sort-disabled)",
      beforeStart: (event, ui) ->
        $(".issues-sortable-list").css "min-height", ui.item.outerHeight()
      stop: (event, ui) ->
        $(".issues-sortable-list").css "min-height", "0px"
      update: (event, ui) ->
        # Prevents sorting from container which element has been removed.
        if $(this).find(ui.item).length > 0
          data = $(this).sortable("serialize")
          Milestone.sortIssues(data)

      receive: (event, ui) ->
        new_state = $(this).data('state')
        issue_id = ui.item.data('iid')
        issue_url = ui.item.data('url')

        data = switch new_state
          when 'ongoing'
            "issue[assignee_id]=" + gon.current_user_id
          when 'unassigned'
            "issue[assignee_id]="
          when 'closed'
            "issue[state_event]=close"

        if $(ui.sender).data('state') == "closed"
          data += "&issue[state_event]=reopen"

        Milestone.updateIssue(ui.item, issue_url, data)

    ).disableSelection()

  bindTabsSwitching: ->
    $('a[data-toggle="tab"]').on 'show.bs.tab', (e) ->
      currentTabClass  = $(e.target).data('show')
      previousTabClass =  $(e.relatedTarget).data('show')

      $(previousTabClass).hide()
      $(currentTabClass).removeClass('hidden')
      $(currentTabClass).show()

  bindMergeRequestSorting: ->
    $("#merge_requests-list-unassigned, #merge_requests-list-ongoing, #merge_requests-list-closed").sortable(
      connectWith: ".merge_requests-sortable-list",
      dropOnEmpty: true,
      items: "li:not(.ui-sort-disabled)",
      beforeStart: (event, ui) ->
        $(".merge_requests-sortable-list").css "min-height", ui.item.outerHeight()
      stop: (event, ui) ->
        $(".merge_requests-sortable-list").css "min-height", "0px"
      update: (event, ui) ->
        data = $(this).sortable("serialize")
        Milestone.sortMergeRequests(data)

      receive: (event, ui) ->
        new_state = $(this).data('state')
        merge_request_id = ui.item.data('iid')
        merge_request_url = ui.item.data('url')

        data = switch new_state
          when 'ongoing'
            "merge_request[assignee_id]=" + gon.current_user_id
          when 'unassigned'
            "merge_request[assignee_id]="
          when 'closed'
            "merge_request[state_event]=close"

        if $(ui.sender).data('state') == "closed"
          data += "&merge_request[state_event]=reopen"

        Milestone.updateMergeRequest(ui.item, merge_request_url, data)

    ).disableSelection()
