@Pager =
  limit: 0
  offset: 0
  disable: false
  init: (limit, preload) ->
    @limit = limit
    if preload
      @offset = 0
      @getOld()
    else
      @offset = limit
    @initLoadMore()

  getOld: ->
    $(".loading").show()
    $.ajax
      type: "GET"
      url: location.href
      data: "limit=" + @limit + "&offset=" + @offset
      complete: ->
        $(".loading").hide()
      success: (data) ->
        Pager.append(data.count, data.html)
      dataType: "json"

  append: (count, html) ->
    $(".content_list").append html
    if count > 0
      @offset += count
    else
      @disable = true

  initLoadMore: ->
    $(document).unbind('scroll')
    $(document).endlessScroll
      bottomPixels: 400
      fireDelay: 1000
      fireOnce: true
      ceaseFire: ->
        Pager.disable

      callback: (i) ->
        $(".loading").show()
        Pager.getOld()
