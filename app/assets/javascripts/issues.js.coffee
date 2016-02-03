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

  reload: ->
    Issues.initSelects()
    Issues.initChecks()
    $('#filter_issue_search').val($('#issue_search').val())

  initSelects: ->
    $("select#update_state_event").select2(width: 'resolve', dropdownAutoWidth: true)
    $("select#update_assignee_id").select2(width: 'resolve', dropdownAutoWidth: true)
    $("select#update_milestone_id").select2(width: 'resolve', dropdownAutoWidth: true)
    $("select#label_name").select2(width: 'resolve', dropdownAutoWidth: true)
    $("#milestone_id, #assignee_id, #label_name").on "change", ->
      $(this).closest("form").submit()

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
      @timer = setTimeout(Issues.filterResults, 500)

  filterResults: =>
    form = $("#issue_search_form")
    search = $("#issue_search").val()
    $('.issues-holder').css("opacity", '0.5')
    issues_url = form.attr('action') + '?' + form.serialize()

    $.ajax
      type: "GET"
      url: form.attr('action')
      data: form.serialize()
      complete: ->
        $('.issues-holder').css("opacity", '1.0')
      success: (data) ->
        $('.issues-holder').html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: issues_url}, document.title, issues_url
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
