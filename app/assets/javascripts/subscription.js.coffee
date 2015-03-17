class @Subscription
  constructor: (url) ->
    $(".subscribe-button").unbind("click").click (event)=>
      btn = $(event.currentTarget)
      action = btn.find("span").text()
      current_status = $(".subscription-status").attr("data-status")
      btn.prop("disabled", true)
      
      $.post url, =>
        btn.prop("disabled", false)
        status = if current_status == "subscribed" then "unsubscribed" else "subscribed"
        $(".subscription-status").attr("data-status", status)
        action = if status == "subscribed" then "Unsubscribe" else "Subscribe"
        btn.find("span").text(action)
        $(".subscription-status>div").toggleClass("hidden")

    
