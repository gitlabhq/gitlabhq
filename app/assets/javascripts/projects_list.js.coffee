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
      if terms == "" || terms == undefined
        uiBox.find("ul.projects-list li").show()
      else
        uiBox.find("ul.projects-list li").each (index) ->
          name = $(this).find("span.filter-title").text()

          if name.toLowerCase().search(terms.toLowerCase()) == -1
            $(this).hide()
          else
            $(this).show()
      uiBox.find("ul.projects-list li.bottom").hide()


