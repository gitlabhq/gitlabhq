class @ProjectSelect
  constructor: ->
    $('.ajax-project-select').each (i, select) =>
      @groupId = $(select).data('group-id')
      @includeGroups = $(select).data('include-groups')
      @orderBy = $(select).data('order-by') || 'id'
      @selectId = $(select).data('select-id') || 'web_url'
      @accessLevel = $(select).data('access-level')
      @withoutId = $(select).data('without-id')

      placeholder = "Search for project"
      placeholder += " or group" if @includeGroups

      $(select).select2
        placeholder: placeholder
        minimumInputLength: 0
        query: (options) =>
          if @groupId
            Api.groupProjects @groupId, options.term, @createCallback(options)
          else
            Api.projects options.term, @orderBy, @createCallback(options)

        id: (project) =>
          project[@selectId]

        text: (project) ->
          project.name_with_namespace || project.name

        dropdownCssClass: "ajax-project-dropdown"

  createCallback: (options) =>
    finalCallback = (projects) ->
      options.callback({ results: projects })

    @withoutIdCallbackDecorator(
      @accessLevelCallbackDecorator(
        @groupsCallbackDecorator(
          finalCallback
        )
      )
    )

  groupsCallbackDecorator: (callback) =>
    return callback unless @includeGroups

    (projects) =>
      Api.groups options.term, false, (groups) =>
        data = groups.concat(projects)
        callback(data)

  accessLevelCallbackDecorator: (callback) =>
    return callback unless @accessLevel

    ##
    # Requires ECMAScript >= 5
    #
    (projects) =>
      data = projects.filter (p) =>
        max = Math.max(p.permissions.group_access?.access_level ? 0,
                       p.permissions.project_access?.access_level ? 0)

        max >= @accessLevel

      callback(data)

  withoutIdCallbackDecorator: (callback) =>
    return callback unless @withoutId

    ##
    # Requires ECMAScript >= 5
    #
    (projects) =>
      data = projects.filter (p) =>
        p.id != @withoutId

      callback(data)
