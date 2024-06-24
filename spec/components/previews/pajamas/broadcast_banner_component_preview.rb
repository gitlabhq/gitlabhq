# frozen_string_literal: true

module Pajamas
  class BroadcastBannerComponentPreview < ViewComponent::Preview
    # @param message text
    # @param id text
    # @param theme text
    # @param dismissable toggle
    # @param expire_date text
    # @param cookie_key text
    # @param dismissal_path text
    def default(
      message: 'Message for the broadcast banner',
      id: '99',
      theme: 'light-indigo',
      dismissable: true,
      expire_date: Time.now.next_year.iso8601,
      cookie_key: 'my_cookie',
      dismissal_path: '/my-path'
    )
      render(Pajamas::BroadcastBannerComponent.new(
        message: message,
        id: id,
        theme: theme,
        dismissable: dismissable,
        expire_date: expire_date,
        cookie_key: cookie_key,
        dismissal_path: dismissal_path
      ))
    end
  end
end
