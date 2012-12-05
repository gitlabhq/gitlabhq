@CommitsList =
  ref: null
  limit: 0
  offset: 0
  disable: false
  init: (ref, limit) ->
    $(".day-commits-table li.commit").on "click", (e) ->
      unless e.target.nodeName is "A"
        location.href = $(this).attr("url")
        e.stopPropagation()
        false

    @ref = ref
    @limit = limit
    @offset = limit
    @initLoadMore()
    $(".loading").show()

  getOld: ->
    $(".loading").show()
    $.ajax
      type: "GET"
      url: location.href
      data: "limit=" + @limit + "&offset=" + @offset + "&ref=" + @ref
      complete: ->
        $(".loading").hide()

      dataType: "script"


  append: (count, html) ->
    $("#commits_list").append html
    if count > 0
      @offset += count
    else
      @disable = true

  initLoadMore: ->
    $(document).endlessScroll
      bottomPixels: 400
      fireDelay: 1000
      fireOnce: true
      ceaseFire: ->
        CommitsList.disable

      callback: (i) ->
        CommitsList.getOld()

