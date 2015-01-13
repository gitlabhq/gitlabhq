$(document).ready ->
  $(window).load (e) ->
    e.preventDefault()
    unless location.hash is ""
      $("html, body").animate
        scrollTop: $(".navbar").offset().top - $(".navbar").height()
      , 200

  $("a").click (event) ->
    link = event.target
    isAnchor = link instanceof HTMLAnchorElement

    if (location.hash != "" || isAnchor)
      $("html,body").animate
        scrollTop: $(this).offset().top - $(".navbar").height() - 3
      , 200
