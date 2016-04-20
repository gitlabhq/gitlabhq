#
# * Filter merge requests
#
@MergeRequests =
  init: ->
    MergeRequests.initSearch()

  # Make sure we trigger ajax request only after user stop typing
  initSearch: ->
    @timer = null
    $("#issue_search").keyup ->
      clearTimeout(@timer)
      @timer = setTimeout(MergeRequests.filterResults, 500)

  filterResults: =>
    form = $("#issue_search_form")
    search = $("#issue_search").val()
    $('.merge-requests-holder').css("opacity", '0.5')
    issues_url = form.attr('action') + '?' + form.serialize()

    $.ajax
      type: "GET"
      url: form.attr('action')
      data: form.serialize()
      complete: ->
        $('.merge-requests-holder').css("opacity", '1.0')
      success: (data) ->
        $('.merge-requests-holder').html(data.html)
        # Change url so if user reload a page - search results are saved
        history.replaceState {page: issues_url}, document.title, issues_url
        MergeRequests.reload()
      dataType: "json"

  reload: ->
    $('#filter_issue_search').val($('#issue_search').val())
