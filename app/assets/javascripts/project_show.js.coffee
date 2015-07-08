class @ProjectShow
  constructor: ->
    $("a[data-toggle='tab']").on "shown.bs.tab", (e) ->
        $.cookie "default_view", $(e.target).attr("href"), { expires: 30, path: '/' }

      defaultView = $.cookie("default_view")
      if defaultView
        $("a[href=" + defaultView + "]").tab "show"
      else
        $("a[data-toggle='tab']:first").tab "show"
