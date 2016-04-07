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

  # Update state filters if present in page
  updateStateFilters: ->
    stateFilters =  $('.issues-state-filters')
    newParams = {}
    paramKeys = ['author_id', 'label_name', 'milestone_title', 'assignee_id', 'issue_search']

    for paramKey in paramKeys
      newParams[paramKey] = gl.utils.getUrlParameter(paramKey) or ''

    if stateFilters.length
      stateFilters.find('a').each ->
        initialUrl = $(this).attr 'href'
        $(this).attr 'href', gl.utils.mergeUrlParams(newParams, initialUrl)

  # Make sure we trigger ajax request only after user stop typing
  initSearch: ->
    @timer = null
    $("#issue_search").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout( ->
        Issues.filterResults $("#issue_search_form")
      , 500)

  filterResults: (form) =>
    # Assume for now there is only 1 multi select field
    # Find the hidden inputs with square brackets
    $multiInputs = form.find('input[name$="[]"]')
    if $multiInputs.length
      # get the name of one of them
      multiInputName = $multiInputs
                          .first()
                          .attr('name')

      # get the singular name by
      # removing the square brackets from the name
      singularName = multiInputName.replace('[]','')
      # clone the form so we can mess around with it.
      $clonedForm = form.clone()

      # get those inputs from the cloned form
      $inputs = $clonedForm
        .find("input[name='#{multiInputName}']")

      # make a comma seperated list of labels
      commaSeperated = $inputs
                          .map( -> $(this).val())
                          .get()
                          .join(',')
      # append on a hidden input with the comma 
      # seperated values in it
      $clonedForm.append(
        $('<input />')
          .attr('type','hidden')
          .attr('name', singularName)
          .val(commaSeperated)
      )
      # remove the multi inputs from the 
      # cloned form so they don't get serialized
      $inputs.remove()
      # serialize the cloned form
      formData = $clonedForm.serialize()
    else
      formData = form.serialize()

    $('.issues-holder, .merge-requests-holder').css("opacity", '0.5')
    formAction = form.attr('action')
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
        Issues.updateStateFilters()
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
