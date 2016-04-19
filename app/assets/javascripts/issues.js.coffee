@Issues =
  init: ->
    Issues.initTemplates()
    Issues.initSearch()
    Issues.initChecks()
    Issues.toggleLabelFilters()

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

  initTemplates: ->
    Issue.labelRow = _.template(
      '<% _.each(labels, function(label){ %>
        <span class="label-row">
          <a href="#"><span class="label color-label has-tooltip" style="background-color: <%= label.color %>; color: #FFFFFF" title="<%= label.description %>" data-container="body"><%= label.title %></span></a>
        </span>
      <% }); %>'
    )

  toggleLabelFilters: ()->
    $filteredLabels = $('.filtered-labels')
    if $filteredLabels.find('.label-row').length > 0
      #$filteredLabels.show()
      $filteredLabels.slideDown().css({'overflow':'visible'})
    else
      #$filteredLabels.hide()
      $filteredLabels.slideUp().css({'overflow':'visible'})

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
    paramKeys = ['author_id', 'milestone_title', 'assignee_id', 'issue_search']

    for paramKey in paramKeys
      newParams[paramKey] = gl.utils.getParameterValues(paramKey)[0] or ''

    if stateFilters.length
      stateFilters.find('a').each ->
        initialUrl = gl.utils.removeParamQueryString($(this).attr('href'), 'label_name[]')
        labelNameValues = gl.utils.getParameterValues('label_name[]')
        if labelNameValues
          labelNameQueryString = ("label_name[]=#{value}" for value in labelNameValues).join('&')
          newUrl = "#{gl.utils.mergeUrlParams(newParams, initialUrl)}&#{labelNameQueryString}"
        else
          newUrl = gl.utils.mergeUrlParams(newParams, initialUrl)
        $(this).attr 'href', newUrl

  # Make sure we trigger ajax request only after user stop typing
  initSearch: ->
    @timer = null
    $("#issue_search").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout( ->
        Issues.filterResults $("#issue_search_form")
      , 500)

  filterResults: (form) =>
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
        $filteredLabels = $('.filtered-labels')
        $filteredLabelsSpans = $filteredLabels.find('.label-row')
        gl.animate.animateEach(
          $filteredLabelsSpans, 'fadeOutDown', 20,
            cssStart:
              opacity: 1
            cssEnd:
              opacity: 0
        ).then( ->
          if typeof Issue.labelRow is 'function'
            $filteredLabels.html(Issue.labelRow(data))
          Issues.toggleLabelFilters()
          $spans = $filteredLabels.find('.label-row')
          $spans.css('opacity', 0)
          return gl.animate.animateEach $spans, 'fadeInUp', 20,
            cssStart:
              opacity: 0
            cssEnd:
              opacity: 1
        )

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
