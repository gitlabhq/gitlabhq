class @ProjectSelect
  constructor: ->
    $('.ajax-project-select').each (i, select) ->
      @groupId = $(select).data('group-id')

      $(select).select2
        placeholder: "Search for project"
        multiple: $(select).hasClass('multiselect')
        minimumInputLength: 0
        query: (query) =>
          callback = (projects) ->
            data = { results: projects }
            query.callback(data)

          if @groupId
            Api.groupProjects @groupId, query.term, callback
          else
            Api.projects query.term, callback

        id: (project) ->
          project.web_url

        text: (project) ->
          project.name_with_namespace

        dropdownCssClass: "ajax-project-dropdown"
