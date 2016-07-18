issuable_created = false
@Issuable =
  init: ->
    unless issuable_created
      issuable_created = true
      Issuable.initTemplates()
      Issuable.initSearch()
      Issuable.initChecks()
      Issuable.initLabelFilterRemove()

  initTemplates: ->
    Issuable.labelRow = _.template(
      '<% _.each(labels, function(label){ %>
        <span class="label-row btn-group" role="group" aria-label="<%- label.title %>" style="color: <%- label.text_color %>;">
          <a href="#" class="btn btn-transparent has-tooltip" style="background-color: <%- label.color %>;" title="<%- label.description %>" data-container="body">
            <%- label.title %>
          </a>
          <button type="button" class="btn btn-transparent label-remove js-label-filter-remove" style="background-color: <%- label.color %>;" data-label="<%- label.title %>">
            <i class="fa fa-times"></i>
          </button>
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
            $form.append "<input type='hidden' name='#{$search.attr('name')}' value='#{_.escape($search.val())}'/>"
          else
            $input.val $search.val()
          Issuable.filterResults $form if $search.val() isnt ''
        , 500)

  initLabelFilterRemove: ->
    $(document)
      .off 'click', '.js-label-filter-remove'
      .on 'click', '.js-label-filter-remove', (e) ->
        $button = $(@)

        # Remove the label input box
        $('input[name="label_name[]"]')
          .filter -> @value is $button.data('label')
          .remove()

        # Submit the form to get new data
        Issuable.filterResults $('.filter-form')

  filterResults: (form) =>
    formData = form.serialize()

    formAction = form.attr('action')
    issuesUrl = formAction
    issuesUrl += ("#{if formAction.indexOf('?') < 0 then '?' else '&'}")
    issuesUrl += formData

    Turbolinks.visit(issuesUrl)

  initChecks: ->
    @issuableBulkActions = $('.bulk-update').data('bulkActions')

    $('.check_all_issues').off('click').on('click', ->
      $('.selected_issue').prop('checked', @checked)
      Issuable.checkChanged()
    )

    $('.selected_issue').off('change').on('change', Issuable.checkChanged.bind(@))


  checkChanged: ->
    checked_issues = $('.selected_issue:checked')
    if checked_issues.length > 0
      ids = $.map checked_issues, (value) ->
        $(value).data('id')

      $('#update_issues_ids').val ids
      $('.issues-other-filters').hide()
      $('.issues_bulk_update').show()
    else
      $('#update_issues_ids').val []
      $('.issues_bulk_update').hide()
      $('.issues-other-filters').show()
      @issuableBulkActions.willUpdateLabels = false

    return true
