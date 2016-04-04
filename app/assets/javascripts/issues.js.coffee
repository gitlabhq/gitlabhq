@Issues =
  init: ->
    Issues.initSearch()
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

  reload: ->
    Issues.initChecks()
    $('#filter_issue_search').val($('#issue_search').val())

  initChecks: ->
    $(".check_all_issues").click ->
      $(".selected_issue").prop("checked", @checked)
      Issues.checkChanged()

    $(".selected_issue").bind "change", Issues.checkChanged

  # Make sure we trigger ajax request only after user stop typing
  initSearch: ->
    @timer = null
    $("#issue_search").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout( ->
        Issues.filterResults $("#issue_search_form")
      , 500)

  filterResults: (form) =>
    $('.issues-holder, .merge-requests-holder').css("opacity", '0.5')
    formAction = form.attr('action')
    formData = form.serialize()
    issuesUrl = formAction
    issuesUrl += ("#{if formAction.indexOf("?") < 0 then '?' else '&'}")
    issuesUrl += formData

    $.ajax
      type: "GET"
      url: formAction
      data: formData
      complete: ->
        $('.issues-holder, .merge-requests-holder').css("opacity", '1.0')
      success: (data) ->
        $('.issues-holder, .merge-requests-holder').html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: issuesUrl}, document.title, issuesUrl
        Issues.reload()
      dataType: "json"

  checkChanged: ->
    checked_issues = $(".selected_issue:checked")
    if checked_issues.length > 0
      ids = []
      $.each checked_issues, (index, value) ->
        ids.push $(value).attr("data-id")

      $("#update_issues_ids").val ids
      $(".issues-other-filters").hide()
      $(".issues_bulk_update").show()
    else
      $("#update_issues_ids").val []
      $(".issues_bulk_update").hide()
      $(".issues-other-filters").show()
