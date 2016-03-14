class @MilestoneSelect
  constructor: ->
    $('.js-milestone-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      milestonesUrl = $(dropdown).data('milestones')
      selectedMilestone = $(dropdown).data('selected')
      showNo = $(dropdown).data('show-no')
      showAny = $(dropdown).data('show-any')
      useId = $(dropdown).data('use-id')

      $(dropdown).glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: milestonesUrl
          ).done (data) ->
            html = $(data)
            data = []
            html.find('.milestone strong a').each ->
              link = $(@).attr("href").split("/")
              data.push(
                id: link[link.length - 1]
                title: $(@).text().trim()
              )

            if showNo
              data.unshift(
                id: "0"
                title: 'No Milestone'
              )

            if showAny
              data.unshift(
                title: 'Any Milestone'
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
          if !useId
            if milestone.title isnt "Any milestone"
              milestone.title
            else
              ""
          else
            milestone.id
        isSelected: (milestone) ->
          milestone.title is selectedMilestone
        clicked: ->
          if $(dropdown).hasClass "js-filter-submit"
            $(dropdown).parents('form').submit()
      )
