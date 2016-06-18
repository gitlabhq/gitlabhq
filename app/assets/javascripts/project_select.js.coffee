class @ProjectSelect
  constructor: ->
    $('.js-projects-dropdown-toggle').each (i, dropdown) ->
      $dropdown = $(dropdown)

      $dropdown.glDropdown(
        filterable: true
        filterRemote: true
        search:
          fields: ['name_with_namespace']
        data: (term, callback) ->
          finalCallback = (projects) ->
            callback projects

          if @includeGroups
            projectsCallback = (projects) ->
              groupsCallback = (groups) ->
                data = groups.concat(projects)
                finalCallback(data)

              Api.groups term, false, groupsCallback
          else
            projectsCallback = finalCallback

          if @groupId
            Api.groupProjects @groupId, term, projectsCallback
          else
            Api.projects term, @orderBy, projectsCallback
        url: (project) ->
          project.web_url
        text: (project) ->
          project.name_with_namespace
      )

    $('.ajax-project-select').each (i, select) ->
      @groupId = $(select).data('group-id')
      @includeGroups = $(select).data('include-groups')
      @orderBy = $(select).data('order-by') || 'id'

      placeholder = "Search for project"
      placeholder += " or group" if @includeGroups

      $(select).select2
        placeholder: placeholder
        minimumInputLength: 0
        query: (query) =>
          finalCallback = (projects) ->
            data = { results: projects }
            query.callback(data)

          if @includeGroups
            projectsCallback = (projects) ->
              groupsCallback = (groups) ->
                data = groups.concat(projects)
                finalCallback(data)

              Api.groups query.term, false, groupsCallback
          else
            projectsCallback = finalCallback

          if @groupId
            Api.groupProjects @groupId, query.term, projectsCallback
          else
            Api.projects query.term, @orderBy, projectsCallback

        id: (project) ->
          project.web_url

        text: (project) ->
          project.name_with_namespace || project.name

        dropdownCssClass: "ajax-project-dropdown"
