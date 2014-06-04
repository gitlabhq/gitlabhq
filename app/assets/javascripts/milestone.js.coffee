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

  constructor: ->
    @bindSorting()

  bindSorting: ->
    $("#issues-list-unassigned, #issues-list-ongoing, #issues-list-closed, #issues-list-reopened").sortable(
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
          when 'reopened'
            "issue[state_event]=reopen"

        Milestone.updateIssue(ui.item, issue_url, data)

    ).disableSelection()

@Milestone = Milestone
