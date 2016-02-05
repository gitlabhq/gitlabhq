class @ProjectsList
  constructor: ->
    $("#project-filter-form-field").off('keyup')
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')

    $("#filter_projects").on 'keyup', ->
      ProjectsList.filter_results($("#filter_projects"))
    $("#project-filter-form-field").on 'keyup', ->
      ProjectsList.filter_results($("#project-filter-form-field"))

  @filter_results: ($element) ->
    terms = $($element).val()
    filterSelector = $($element).data('filter-selector') || 'span.filter-title'

    if not terms
      $("ul.projects-list li").show()
      $('.gl-pagination').show()
    else
      $("ul.projects-list li").each (index) ->
        $this = $(this)
        name = $this.find(filterSelector).text()

        if name.toLowerCase().indexOf(terms.toLowerCase()) == -1
          $this.hide()
        else
          $this.show()
      $('.gl-pagination').hide()
