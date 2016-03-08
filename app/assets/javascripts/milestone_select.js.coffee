class @MilestoneSelect
  constructor: ->
    $('.js-milestone-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      selectedMilestone = $(dropdown).data('selected')

      $(dropdown).glDropdown(
        data: (callback) ->
          Api.milestones projectId, callback
        filterable: true
        search:
          fields: ['name']
        selectable: true
        fieldName: $(dropdown).data('field-name')
        text: (milestone) ->
          milestone.title
        id: (milestone) ->
          milestone.title
        isSelected: (milestone) ->
          milestone.title is selectedMilestone
        clicked: ->
          $(dropdown).parents('form').submit()
      )
