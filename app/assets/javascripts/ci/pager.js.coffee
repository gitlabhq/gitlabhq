@CiPager =
  init: (@url, @limit = 0, preload, @disable = false) ->
    if preload
      @offset = 0
      @getItems()
    else
      @offset = @limit
    @initLoadMore()

  getItems: ->
    $(".loading").show()
    $.ajax
      type: "GET"
      url: @url
      data: "limit=" + @limit + "&offset=" + @offset
      complete: =>
        $(".loading").hide()
      success: (data) =>
        CiPager.append(data.count, data.html)
      dataType: "json"

  append: (count, html) ->
    if count > 1
      $(".content-list").append html
    if count == @limit
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
        CiPager.disable

      callback: (i) =>
        unless $(".loading").is(':visible')
          $(".loading").show()
          CiPager.getItems()
