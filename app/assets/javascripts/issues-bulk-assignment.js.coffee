class @IssuableBulkActions
  constructor: (opts = {}) ->
    # Set defaults
    {
      @container = $('.content')
      @form = @getElement('.bulk-update')
      @issues = @getElement('.issues-list .issue')
    } = opts

    # Save instance
    @form.data 'bulkActions', @

    @willUpdateLabels = false

    @bindEvents()

    # Fixes bulk-assign not working when navigating through pages
    Issuable.initChecks();

  getElement: (selector) ->
    @container.find selector

  bindEvents: ->
    @form.off('submit').on('submit', @onFormSubmit.bind(@))

  onFormSubmit: (e) ->
    e.preventDefault()
    @submit()

  submit: ->
    _this = @

    xhr = $.ajax
            url: @form.attr 'action'
            method: @form.attr 'method'
            dataType: 'JSON',
            data: @getFormDataAsObject()

    xhr.done (response, status, xhr) ->
      location.reload()

    xhr.fail ->
      new Flash("Issue update failed")

    xhr.always @onFormSubmitAlways.bind(@)

  onFormSubmitAlways: ->
    @form.find('[type="submit"]').enable()

  getSelectedIssues: ->
    @issues.has('.selected_issue:checked')

  getLabelsFromSelection: ->
    labels = []

    @getSelectedIssues().map ->
      _labels = $(@).data('labels')
      if _labels
        _labels.map (labelId) ->
          labels.push(labelId) if labels.indexOf(labelId) is -1

    labels

  ###*
   * Will return only labels that were marked previously and the user has unmarked
   * @return {Array} Label IDs
  ###
  getUnmarkedIndeterminedLabels: ->
    result = []
    labelsToKeep = []

    for el in @getElement('.labels-filter .is-indeterminate')
      labelsToKeep.push $(el).data('labelId')

    for id in @getLabelsFromSelection()
      # Only the ones that we are not going to keep
      result.push(id) if labelsToKeep.indexOf(id) is -1

    result

  ###*
   * Simple form serialization, it will return just what we need
   * Returns key/value pairs from form data
  ###
  getFormDataAsObject: ->
    formData =
      update:
        state_event        : @form.find('input[name="update[state_event]"]').val()
        assignee_id        : @form.find('input[name="update[assignee_id]"]').val()
        milestone_id       : @form.find('input[name="update[milestone_id]"]').val()
        issues_ids         : @form.find('input[name="update[issues_ids]"]').val()
        subscription_event : @form.find('input[name="update[subscription_event]"]').val()
        add_label_ids      : []
        remove_label_ids   : []

    if @willUpdateLabels
      @getLabelsToApply().map (id) ->
        formData.update.add_label_ids.push id

      @getLabelsToRemove().map (id) ->
        formData.update.remove_label_ids.push id

    formData

  getLabelsToApply: ->
    labelIds = []
    $labels = @form.find('.labels-filter input[name="update[label_ids][]"]')

    $labels.each (k, label) ->
      labelIds.push parseInt($(label).val()) if label

    labelIds

  ###*
   * Returns Label IDs that will be removed from issue selection
   * @return {Array} Array of labels IDs
  ###
  getLabelsToRemove: ->
    result = []
    indeterminatedLabels = @getUnmarkedIndeterminedLabels()
    labelsToApply = @getLabelsToApply()

    indeterminatedLabels.map (id) ->
      # We need to exclude label IDs that will be applied
      # By not doing this will cause issues from selection to not add labels at all
      result.push(id) if labelsToApply.indexOf(id) is -1

    result
