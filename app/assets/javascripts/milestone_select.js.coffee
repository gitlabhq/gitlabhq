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
      showUpcoming = $dropdown.data('show-upcoming')
      useId = $dropdown.data('use-id')
      defaultLabel = $dropdown.data('default-label')
      issuableId = $dropdown.data('issuable-id')
      abilityName = $dropdown.data('ability-name')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon')
      $value = $block.find('.value')
      $loading = $block.find('.block-loading').fadeOut()

      if issueUpdateURL
        milestoneLinkTemplate = _.template(
          '<a href="/<%- namespace %>/<%- path %>/milestones/<%- iid %>" class="bold has-tooltip" data-container="body" title="<%- remaining %>"><%- title %></a>'
        )

        milestoneLinkNoneTemplate = '<span class="no-value">None</span>'

        collapsedSidebarLabelTemplate = _.template(
          '<span class="has-tooltip" data-container="body" title="<%- remaining %>" data-placement="left">
            <%- title %>
          </span>'
        )

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: milestonesUrl
          ).done (data) ->
            extraOptions = []
            if showAny
              extraOptions.push(
                id: 0
                name: ''
                title: 'Any Milestone'
              )

            if showNo
              extraOptions.push(
                id: -1
                name: 'No Milestone'
                title: 'No Milestone'
              )

            if showUpcoming
              extraOptions.push(
                id: -2
                name: '#upcoming'
                title: 'Upcoming'
              )

            if extraOptions.length > 0
              extraOptions.push 'divider'

            callback(extraOptions.concat(data))
        filterable: true
        search:
          fields: ['title']
        selectable: true
        toggleLabel: (selected, el, e) ->
          if selected and 'id' of selected and $(el).hasClass('is-active')
            selected.title
          else
            defaultLabel
        defaultLabel: defaultLabel
        fieldName: $dropdown.data('field-name')
        text: (milestone) ->
          _.escape(milestone.title)
        id: (milestone) ->
          if not useId and not $dropdown.is('.js-issuable-form-dropdown')
            milestone.name
          else
            milestone.id
        isSelected: (milestone) ->
          milestone.name is selectedMilestone
        hidden: ->
          $selectbox.hide()

          # display:block overrides the hide-collapse rule
          $value.css('display', '')
        clicked: (selected, $el, e) ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is page is 'projects:merge_requests:index'

          if $dropdown.hasClass('js-filter-bulk-update') or $dropdown.hasClass('js-issuable-form-dropdown')
            e.preventDefault()
            return

          if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
            if selected.name?
              selectedMilestone = selected.name
            else
              selectedMilestone = ''
            Issuable.filterResults $dropdown.closest('form')
          else if $dropdown.hasClass('js-filter-submit')
            $dropdown.closest('form').submit()
          else
            selected = $selectbox
              .find('input[type="hidden"]')
              .val()
            data = {}
            data[abilityName] = {}
            data[abilityName].milestone_id = if selected? then selected else null
            $loading
              .fadeIn()
            $dropdown.trigger('loading.gl.dropdown')
            $.ajax(
              type: 'PUT'
              url: issueUpdateURL
              data: data
            ).done (data) ->
              $dropdown.trigger('loaded.gl.dropdown')
              $loading.fadeOut()
              $selectbox.hide()
              $value.css('display', '')
              if data.milestone?
                data.milestone.namespace = _this.currentProject.namespace
                data.milestone.path = _this.currentProject.path
                data.milestone.remaining = $.timefor data.milestone.due_date
                $value.html(milestoneLinkTemplate(data.milestone))
                $sidebarCollapsedValue.find('span').html(collapsedSidebarLabelTemplate(data.milestone))
              else
                $value.html(milestoneLinkNoneTemplate)
                $sidebarCollapsedValue.find('span').text('No')
      )
