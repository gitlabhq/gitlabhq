class @Subscription
  constructor: (container) ->
    $container = $(container)
    @url = $container.attr('data-url')
    @subscribeButton = $container.find('.js-subscribe-button')
    @subscribeButton.off('click').click(@toggleSubscription)
    @subscribedHTML = '<i class="fa fa-volume-up"></i> Unsubscribe'
    @unsubscribedHTML = '<i class="fa fa-volume-off"></i> Subscribe'

  toggleSubscription: (e) =>
    btn = $(e.currentTarget)
    subscribed = @subscribeButton.attr('data-subscribed')?
    btn
      .addClass('disabled')
      .prop('disabled','disabled')

    $.post @url, =>
      subscribed = not subscribed
      btn
        .removeClass('disabled')
        .prop('disabled', false);
      if subscribed
        @subscribeButton.attr('data-subscribed',true)
        btn.html(@subscribedHTML)
        btn.closest('div').find('.negation').hide()
        return
      else
        @subscribeButton.removeAttr('data-subscribed', subscribed)
        btn.html(@unsubscribedHTML)
        btn.closest('div').find('.negation').show()
        return
    return
