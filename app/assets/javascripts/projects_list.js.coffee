@ProjectsList =
  init: ->
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')
      list.find("li").show()
      list.find("li.bottom").hide()
    this.initSearch()

  initSearch: ->
    @timer = null
    $("#projects-list-filter").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout(ProjectsList.filterResults, 500)

  filterResults: =>
    form = $("#project-list-form")
    search = $("#issue_search").val()
    uiBox = $('div.projects-list-holder')

    $('.projects-list-holder').css("opacity", '0.5')

    project_filter_url = form.attr('action') + '?' + form.serialize()
    $.ajax
      type: "GET"
      url: form.attr('action')
      data: form.serialize()
      complete: ->
        $('.projects-list-holder').css("opacity", '1.0')
      success: (data) ->
        $('.projects-list-holder').html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: project_filter_url}, document.title, project_filter_url
      dataType: "json"
    uiBox.find("ul.projects-list li.bottom").hide()
