class @ProjectsList
  constructor: ->
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')

    $("#filter_projects").on 'keyup', ->
      ProjectsList.filter_results($("#filter_projects"))

  @filter_results: ($element) ->
    terms = $element.val()
    filterSelector = $element.data('filter-selector') || 'span.filter-title'

    if not terms
      $(".projects-list li").show()
      $('.gl-pagination').show()
    else
      $(".projects-list li").each (index) ->
        $this = $(this)
        name = $this.find(filterSelector).text()

        if name.toLowerCase().indexOf(terms.toLowerCase()) == -1
          $this.hide()
        else
          $this.show()
      $('.gl-pagination').hide()
