class @ProjectsList
  constructor: ->
    $("#project-filter-form-field").unbind()
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')

    $("#filter_projects").keyup ->
      ProjectsList.filter_results("#filter_projects")
    $("#project-filter-form-field").keyup ->
      ProjectsList.filter_results("#project-filter-form-field")

  @filter_results: (element) ->
    terms = $(element).val()
    filterSelector = $(element).data('filter-selector') || 'span.filter-title'

    if terms == "" || terms == undefined
      $("ul.projects-list li").show()
      $('.gl-pagination').show()
    else
      $("ul.projects-list li").each (index) ->
        name = $(this).find(filterSelector).text()

        if name.toLowerCase().search(terms.toLowerCase()) == -1
          $(this).hide()
        else
          $(this).show()
      $('.gl-pagination').hide()
