class @ProjectsList
  constructor: ->
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')
      list.find("li").show()
      list.find("li.bottom").hide()

    $(".projects-list-filter").keyup ->
      terms = $(this).val()
      uiBox = $('div.projects-list-holder')
      filterSelector = $(this).data('filter-selector') || 'span.filter-title'

      $('.projects-list-holder').css("opacity", '0.5')
      form = $("#project-list-form")
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
