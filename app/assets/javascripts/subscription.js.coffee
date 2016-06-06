class @Subscription
  constructor: (container) ->
    $container = $(container)
    @url = $container.attr('data-url')
    @subscribeButton = $container.find('.js-subscribe-button')
    @subscribeButton
      .off('click')
      .on('click', @toggleSubscription)

  toggleSubscription: =>
    subscribed = @subscribeButton.attr('data-subscribed')?
    @subscribeButton
      .addClass('disabled')
      .prop('disabled', 'disabled')

    $.post @url, =>
      subscribed = not subscribed
      @subscribeButton
        .removeClass('disabled')
        .prop('disabled', false)
        .find('.fa')
        .toggleClass 'fa-volume-up fa-volume-off'

      if subscribed
        @subscribeButton
          .attr('data-subscribed', true)
          .find('.subscribe-text')
          .text(@subscribeButton.data("unsubscribe-text"))
          .closest('.subscription')
          .find('.negation')
          .hide()
      else
        @subscribeButton
          .removeAttr('data-subscribed', subscribed)
          .find('.subscribe-text')
          .text(@subscribeButton.data("subscribe-text"))
          .closest('.subscription')
          .find('.negation')
          .show()
