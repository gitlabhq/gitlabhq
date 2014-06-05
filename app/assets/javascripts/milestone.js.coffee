class Milestone
  @updateIssue: (li, issue_url, data) ->
    $.ajax
      type: "PUT"
      url: issue_url
      data: data
      success: (data) ->
        if data.saved == true
          $(li).effect 'highlight'
        else
          new Flash("Issue update failed", 'alert')
      dataType: "json"

  @updateMergeRequest: (li, merge_request_url, data) ->
    $.ajax
      type: "PUT"
      url: merge_request_url
      data: data
      success: (data) ->
        if data.saved == true
          $(li).effect 'highlight'
        else
          new Flash("Issue update failed", 'alert')
      dataType: "json"

  constructor: ->
    @bindIssuesSorting()
    @bindMergeRequestSorting()

  bindIssuesSorting: ->
    $("#issues-list-unassigned, #issues-list-ongoing, #issues-list-closed").sortable(
      connectWith: ".issues-sortable-list",
      dropOnEmpty: true,
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

  bindMergeRequestSorting: ->
    $("#merge_requests-list-unassigned, #merge_requests-list-ongoing, #merge_requests-list-closed").sortable(
      connectWith: ".merge_requests-sortable-list",
      dropOnEmpty: true,
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

@Milestone = Milestone
