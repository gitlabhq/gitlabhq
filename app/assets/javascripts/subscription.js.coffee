class @Subscription
  constructor: (container) ->
    $container = $(container)
    @url = $container.attr('data-url')
    @subscribe_button = $container.find('.subscribe-button')
    @subscription_status = $container.find('.subscription-status')
    @subscribe_button.unbind('click').click(@toggleSubscription)

  toggleSubscription: (event) =>
    btn = $(event.currentTarget)
    action = btn.find('span').text()
    current_status = @subscription_status.attr('data-status')
    btn.addClass('disabled')

    $.post @url, =>
      btn.removeClass('disabled')
      status = if current_status == 'subscribed' then 'unsubscribed' else 'subscribed'
      @subscription_status.attr('data-status', status)
      action = if status == 'subscribed' then 'Unsubscribe' else 'Subscribe'
      btn.find('span').text(action)
      @subscription_status.find('>div').toggleClass('hidden')
