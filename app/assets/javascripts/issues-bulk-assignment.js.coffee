class @IssuableBulkActions
  constructor: (opts = {}) ->
    # Set defaults
    {
      @container = $('.content')
      @form = @getElement('.bulk-update')
      @issues = @getElement('.issues-list .issue')
    } = opts

    @bindEvents()

  getElement: (selector) ->
    @container.find selector

  bindEvents: ->
    @form.on 'submit', @onFormSubmit.bind(@)

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
      Turbolinks.visit(location.href)

    xhr.fail ->
      console.error 'fail'

    xhr.always ->
      _this.onFormSubmitAlways()

  onFormSubmitAlways: ->
    @form.find('[type="submit"]').enable()

  getSelectedIssues: ->
    @issues.has('.selected_issue:checked')

  getLabelsFromSelection: ->
    labels = []

    @getSelectedIssues().map ->
      _labels = $(@).data('labels')
      if _labels
        _labels.map (labelId)->
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
        issues_ids: @form.find('#update_issues_ids').val()
        add_label_ids: []
        remove_label_ids: []

    for id in @getLabelsToApply()
      formData.update.add_label_ids.push id

    for id in @getLabelsToRemove()
      formData.update.remove_label_ids.push id

    formData

  getLabelsToApply: ->
    labelIds = []
    $labels = @form.find('.labels-filter input[name="update[label_ids][]"]')

    for label in $labels
      labelIds.push $(label).val() if label

    labelIds

  ###*
   * Just an alias of @getUnmarkedIndeterminedLabels
   * @return {Array} Array of labels
  ###
  getLabelsToRemove: ->
    @getUnmarkedIndeterminedLabels()
