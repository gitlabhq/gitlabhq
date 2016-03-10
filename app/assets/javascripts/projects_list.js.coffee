class @ProjectsList
  constructor: ->
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      $projectsList = $(this).closest('.projects-list')
      ProjectsList.showPagination($projectsList)
      $projectsList.find('li.bottom').hide()

    $("#filter_projects").on 'keyup', ->
      ProjectsList.filter_results($("#filter_projects"))

  @showPagination: ($projectsList) ->
    $projectsList.find('li').show()
    $('.gl-pagination').show()

  @filter_results: ($element) ->
    terms = $element.val()
    filterSelector = $element.data('filter-selector') || 'span.filter-title'
    $projectsList = $('.projects-list')

    if not terms
      ProjectsList.showPagination($projectsList)
    else
      $projectsList.find('li').each (index) ->
        $this = $(this)
        name = $this.find(filterSelector).text()

        if name.toLowerCase().indexOf(terms.toLowerCase()) == -1
          $this.hide()
        else
          $this.show()
      $('.gl-pagination').hide()
