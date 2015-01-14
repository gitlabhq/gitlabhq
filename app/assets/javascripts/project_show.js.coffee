class @ProjectShow
  constructor: ->
    $('.project-home-panel .star').on 'ajax:success', (e, data, status, xhr) ->
      $(@).toggleClass('on').find('.count').html(data.star_count)
    .on 'ajax:error', (e, xhr, status, error) ->
      new Flash('Star toggle failed. Try again later.', 'alert')

    $("a[data-toggle='tab']").on "shown.bs.tab", (e) ->
        $.cookie "default_view", $(e.target).attr("href")

      defaultView = $.cookie("default_view")
      if defaultView
        $("a[href=" + defaultView + "]").tab "show"
      else
        $("a[data-toggle='tab']:first").tab "show"
