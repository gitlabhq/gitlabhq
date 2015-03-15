class @Subscription
  constructor: (url) ->
    $(".subscribe-button").click (event)=>
      self = @
      btn = $(event.currentTarget)
      action = btn.prop("value")
      current_status = $(".sub_status").text().trim()
      $(".fa-spinner.subscription").removeClass("hidden")
      $(".sub_status").empty()
      
      $.post url, subscription: action, =>
        $(".fa-spinner.subscription").addClass("hidden")
        status = if current_status == "subscribed" then "unsubscribed" else "subscribed"
        $(".sub_status").text(status)
        action = if status == "subscribed" then "Unsubscribe" else "Subscribe"
        btn.prop("value", action)

    
