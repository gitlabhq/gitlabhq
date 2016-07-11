@ProjectsList =
  init: ->
    $(".projects-list-filter").off('keyup')
    this.initSearch()
    this.initPagination()

  initSearch: ->
    projectsListFilter = $('.projects-list-filter')
    debounceFilter = _.debounce ProjectsList.filterResults, 500
    projectsListFilter.on 'keyup', (e) ->
      debounceFilter() if projectsListFilter.val() isnt ''

  filterResults: ->
    $('.projects-list-holder').fadeTo(250, 0.5)

    form = null
    form = $("form#project-filter-form")
    search = $(".projects-list-filter").val()
    project_filter_url = form.attr('action') + '?' + form.serialize()

    $.ajax
      type: "GET"
      url: form.attr('action')
      data: form.serialize()
      complete: ->
        $('.projects-list-holder').fadeTo(250, 1)
      success: (data) ->
        $('.projects-list-holder').replaceWith(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: project_filter_url}, document.title, project_filter_url
      dataType: "json"

  initPagination: ->
    $('.projects-list-holder .pagination').on('ajax:success', (e, data) ->
      $('.projects-list-holder').replaceWith(data.html)
    )
