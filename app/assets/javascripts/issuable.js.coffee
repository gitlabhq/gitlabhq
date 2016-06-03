@Issuable =
  init: ->
    Issuable.initTemplates()
    Issuable.initSearch()

  initTemplates: ->
    Issuable.labelRow = _.template(
      '<% _.each(labels, function(label){ %>
        <span class="label-row">
          <a href="#"><span class="label color-label has-tooltip" style="background-color: <%= label.color %>; color: <%= label.text_color %>" title="<%= _.escape(label.description) %>" data-container="body"><%= _.escape(label.title) %></span></a>
        </span>
      <% }); %>'
    )

  initSearch: ->
    @timer = null
    $('#issue_search')
      .off 'keyup'
      .on 'keyup', ->
        clearTimeout(@timer)
        @timer = setTimeout( ->
          Issuable.filterResults $('#issue_search_form')
        , 500)

  toggleLabelFilters: ->
    $filteredLabels = $('.filtered-labels')
    if $filteredLabels.find('.label-row').length > 0
      $filteredLabels.removeClass('hidden')
    else
      $filteredLabels.addClass('hidden')

  filterResults: (form) =>
    formData = form.serialize()

    $('.issues-holder, .merge-requests-holder').css('opacity', '0.5')
    formAction = form.attr('action')
    issuesUrl = formAction
    issuesUrl += ("#{if formAction.indexOf('?') < 0 then '?' else '&'}")
    issuesUrl += formData
    $.ajax
      type: 'GET'
      url: formAction
      data: formData
      complete: ->
        $('.issues-holder, .merge-requests-holder').css('opacity', '1.0')
      success: (data) ->
        $('.issues-holder, .merge-requests-holder').html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: issuesUrl}, document.title, issuesUrl
        Issuable.reload()
        Issuable.updateStateFilters()
        $filteredLabels = $('.filtered-labels')

        if typeof Issuable.labelRow is 'function'
          $filteredLabels.html(Issuable.labelRow(data))

        Issuable.toggleLabelFilters()

      dataType: "json"

  reload: ->
    if Issues.created
      Issues.initChecks()

    $('#filter_issue_search').val($('#issue_search').val())

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
