@Issues =
  init: ->
    Issues.initSearch()
    Issues.initSelects()
    Issues.initChecks()

    $("body").on "ajax:success", ".close_issue, .reopen_issue", ->
      t = $(this)
      totalIssues = undefined
      reopen = t.hasClass("reopen_issue")
      $(".issue_counter").each ->
        issue = $(this)
        totalIssues = parseInt($(this).html(), 10)
        if reopen and issue.closest(".main_menu").length
          $(this).html totalIssues + 1
        else
          $(this).html totalIssues - 1
    $("body").on "click", ".issues-filters .dropdown-menu a", ->
      $('.issues-list').block(
        message: null,
        overlayCSS:
          backgroundColor: '#DDD'
          opacity: .4
      )
  
  reload: ->
    Issues.initSelects()
    Issues.initChecks()
    $('#filter_issue_search').val($('#issue_search').val())

  initSelects: ->
    $("#update_status").chosen()
    $("#update_assignee_id").chosen()
    $("#update_milestone_id").chosen()
    $("#label_name").chosen()
    $("#assignee_id").chosen()
    $("#milestone_id").chosen()
    $("#milestone_id, #assignee_id, #label_name").on "change", ->
      $(this).closest("form").submit()

  initChecks: ->
    $(".check_all_issues").click ->
      $(".selected_issue").attr "checked", @checked
      Issues.checkChanged()

    $(".selected_issue").bind "change", Issues.checkChanged


  initSearch: ->
    form = $("#issue_search_form")
    last_terms = ""
    $("#issue_search").keyup ->
      terms = $(this).val()
      unless terms is last_terms
        last_terms = terms
        if terms.length >= 2 or terms.length is 0
          form.submit()

  checkChanged: ->
    checked_issues = $(".selected_issue:checked")
    if checked_issues.length > 0
      ids = []
      $.each checked_issues, (index, value) ->
        ids.push $(value).attr("data-id")

      $("#update_issues_ids").val ids
      $(".issues-filters").hide()
      $(".issues_bulk_update").show()
    else
      $("#update_issues_ids").val []
      $(".issues_bulk_update").hide()
      $(".issues-filters").show()
