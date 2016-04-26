issuable_created = false
@Issuable =
  init: ->
    if not issuable_created
      issuable_created = true
      Issuable.initTemplates()
      Issuable.initSearch()
      Issuable.initChecks()

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
          $search = $('#issue_search')
          $form = $('.js-filter-form')
          $input = $("input[name='#{$search.attr('name')}']", $form)

          if $input.length is 0
            $form.append "<input type='hidden' name='#{$search.attr('name')}' value='#{$search.val()}'/>"
          else
            $input.val $search.val()

          Issuable.filterResults $form
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
    if Issuable.created
      Issuable.initChecks()

    $('#filter_issue_search').val($('#issue_search').val())

  initChecks: ->
    $('.check_all_issues').on 'click', ->
      $('.selected_issue').prop('checked', @checked)
      Issuable.checkChanged()

    $('.selected_issue').on 'change', Issuable.checkChanged

  updateStateFilters: ->
    stateFilters =  $('.issues-state-filters, .dropdown-menu-sort')
    newParams = {}
    paramKeys = ['author_id', 'milestone_title', 'assignee_id', 'issue_search', 'issue_search']

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

  checkChanged: ->
    checked_issues = $('.selected_issue:checked')
    if checked_issues.length > 0
      ids = []
      $.each checked_issues, (index, value) ->
        ids.push $(value).data('id')

      $('#update_issues_ids').val ids
      $('.issues-other-filters').hide()
      $('.issues_bulk_update').show()
    else
      $('#update_issues_ids').val []
      $('.issues_bulk_update').hide()
      $('.issues-other-filters').show()
