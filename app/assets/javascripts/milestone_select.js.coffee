class @MilestoneSelect
  constructor: ->
    $('.js-milestone-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      selectedMilestone = $(dropdown).data('selected')
      showNo = $(dropdown).data('show-no')
      showAny = $(dropdown).data('show-any')

      $(dropdown).glDropdown(
        data: (term, callback) ->
          Api.milestones projectId, (data) ->
            data = $.map data, (milestone) ->
              return milestone if milestone.state isnt "closed"

            if showNo
              data.unshift(
                title: 'No milestone'
              )
              
            if showAny
              data.unshift(
                title: 'Any milestone'
              )

            if data.length > 2
              data.splice 2, 0, "divider"

            callback(data)
        filterable: true
        search:
          fields: ['title']
        selectable: true
        fieldName: $(dropdown).data('field-name')
        text: (milestone) ->
          milestone.title
        id: (milestone) ->
          if milestone.title isnt "Any milestone"
            milestone.title
          else
            ""
        isSelected: (milestone) ->
          milestone.title is selectedMilestone
        clicked: ->
          $(dropdown).parents('form').submit()
      )
