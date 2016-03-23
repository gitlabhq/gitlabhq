class @MilestoneSelect
  constructor: (currentProject) ->
    if currentProject?
      _this = @
      @currentProject = JSON.parse(currentProject)
    $('.js-milestone-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      projectId = $dropdown.data('project-id')
      milestonesUrl = $dropdown.data('milestones')
      issueUpdateURL = $dropdown.data('issueUpdate')
      selectedMilestone = $dropdown.data('selected')
      showNo = $dropdown.data('show-no')
      showAny = $dropdown.data('show-any')
      useId = $dropdown.data('use-id')
      defaultLabel = $dropdown.data('default-label')
      issuableId = $dropdown.data('issuable-id')
      abilityName = $dropdown.data('ability-name')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      $value = $block.find('.value')
      $loading = $block.find('.block-loading').fadeOut()

      if issueUpdateURL
        milestoneLinkTemplate = _.template(
          '<a href="/<%= namespace %>/<%= path %>/milestones/<%= iid %>"><%= title %></a>'
        )

        milestoneLinkNoneTemplate = '<div class="light">None</div>'

      extraOptions = [{
        isAny: true
        title: 'Any Milestone'
      }, {
        id: '0'
        title: 'No Milestone'
      }, {
        upcoming: true
        id: '#upcoming'
        title: 'Upcoming'
      }]

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: milestonesUrl
          ).done (data) ->
            if $dropdown.hasClass "js-extra-options"
              if showNo
                data.unshift(
                  id: '0'
                  title: 'No Milestone'
                )

              if showAny
                data.unshift(
                  isAny: true
                  title: 'Any Milestone'
                )

              if data.length > 2
                data.splice 2, 0, 'divider'
            callback(data)
        filterable: true
        search:
          fields: ['title']
        selectable: true
        toggleLabel: (selected) ->
          if selected && 'id' of selected
            selected.title
          else
            defaultLabel
        fieldName: $dropdown.data('field-name')
        text: (milestone) ->
          milestone.title
        id: (milestone) ->
          if !useId
            if !milestone.isAny?
              milestone.title
            else
              ''
          else
            milestone.id
        isSelected: (milestone) ->
          milestone.title is selectedMilestone
        hidden: ->
          $selectbox.hide()
          $value.show()
        clicked: (selected) ->
          if $dropdown.hasClass 'js-filter-bulk-update'
            return

          if $dropdown.hasClass 'js-filter-submit'
            if selected.title?
              selectedMilestone = selected.title
            $dropdown.parents('form').submit()
          else
            selected = $selectbox
              .find('input[type="hidden"]')
              .val()
            data = {}
            data[abilityName] = {}
            data[abilityName].milestone_id = selected
            $loading
              .fadeIn()
            $.ajax(
              type: 'PUT'
              url: issueUpdateURL
              data: data
            ).done (data) ->
              $loading.fadeOut()
              $selectbox.hide()
              $milestoneLink = $value
                      .show()
                      .find('a')
              if data.milestone?
                data.milestone.namespace = _this.currentProject.namespace
                data.milestone.path = _this.currentProject.path
                $value.html(milestoneLinkTemplate(data.milestone))
              else
                $value.html(milestoneLinkNoneTemplate)
      )
