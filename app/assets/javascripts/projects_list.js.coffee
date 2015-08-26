class @ProjectsList
  constructor: ->
    $(".projects-list .js-expand").on 'click', (e) ->
      e.preventDefault()
      list = $(this).closest('.projects-list')
      list.find("li").show()
      list.find("li.bottom").hide()

    $(".projects-list-filter").keyup ->
      terms = $(this).val()
      uiBox = $(this).closest('.projects-list-holder')
      if terms == "" || terms == undefined
        uiBox.find(".projects-list li").show()
      else
        uiBox.find(".projects-list li").each (index) ->
          name = $(this).find(".filter-title").text()

          if name.toLowerCase().search(terms.toLowerCase()) == -1
            $(this).hide()
          else
            $(this).show()
      uiBox.find(".projects-list li.bottom").hide()


