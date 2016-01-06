class @CommitsList
  @timer = null

  @init: (ref, limit) ->
    $("body").on "click", ".day-commits-table li.commit", (event) ->
      if event.target.nodeName != "A"
        location.href = $(this).attr("url")
        e.stopPropagation()
        return false

    Pager.init limit, true

    @content = $("#commits-list")
    @searchField = $("#commits-search")
    @initSearch()

  @initSearch: ->
    @timer = null
    @searchField.keyup =>
      clearTimeout(@timer)
      @timer = setTimeout(@filterResults, 500)

  @filterResults: =>
    form = $(".commits-search-form")
    search = @searchField.val()
    commitsUrl = form.attr("action") + '?' + form.serialize()
    @setOpacitiy("0.5")

    $.ajax
      type: "GET"
      url: form.attr("action")
      data: form.serialize()
      complete: =>
        @setOpacitiy("1.0")
      success: (data) =>
        @content.html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: commitsUrl}, document.title, commitsUrl
      dataType: "json"

  @setOpacitiy: (opacity) ->
    @content.css("opacity", opacity)
