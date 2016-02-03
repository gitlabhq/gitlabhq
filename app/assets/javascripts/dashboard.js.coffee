@Dashboard =
  init: ->
    this.initSearch()

  initSearch: ->
    @timer = null
    $("#project-filter-form-field").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout(Dashboard.filterResults, 500)

  filterResults: =>
    $('.projects-list-holder').css("opacity", '0.5')

    form = null
    form = $("#project-filter-form")
    search = $("#project-filter-form-field").val()
    project_filter_url = form.attr('action') + '?' + form.serialize()

    $.ajax
      type: "GET"
      url: form.attr('action')
      data: form.serialize()
      complete: ->
        $('.projects-list-holder').css("opacity", '1.0')
      success: (data) ->
        $('div.projects-list-holder').replaceWith(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: project_filter_url}, document.title, project_filter_url
      dataType: "json"
    #uiBox.find("ul.projects-list li.bottom").hide()
