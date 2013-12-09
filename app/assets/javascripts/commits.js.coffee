class CommitsList
  @data =
    ref: null
    limit: 0
    offset: 0
  @disable = false

  @showProgress: ->
    $('.loading').show()

  @hideProgress: ->
    $('.loading').hide()

  @init: (ref, limit) ->
    $(".day-commits-table li.commit").live 'click', (event) ->
      if event.target.nodeName != "A"
        location.href = $(this).attr("url")
        e.stopPropagation()
        return false

    @data.ref = ref
    @data.limit = limit
    @data.offset = limit

    this.initLoadMore()
    this.showProgress()

  @getOld: ->
    this.showProgress()
    $.ajax
      type: "GET"
      url: location.href
      data: @data
      complete: this.hideProgress
      success: (data) ->
        CommitsList.append(data.count, data.html)
      dataType: "json"

  @append: (count, html) ->
    $("#commits-list").append(html)
    if count > 0
      @data.offset += count
    else
      @disable = true

  @initLoadMore: ->
    $(document).unbind('scroll')
    $(document).endlessScroll
      bottomPixels: 400
      fireDelay: 1000
      fireOnce: true
      ceaseFire: =>
        @disable
      callback: =>
        this.getOld()

this.CommitsList = CommitsList
