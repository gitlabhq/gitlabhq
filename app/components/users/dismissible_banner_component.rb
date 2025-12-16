# frozen_string_literal: true

module Users
  class DismissibleBannerComponent < Pajamas::BannerComponent
    include UserDismissible

    def initialize(args = {})
      @dismiss_options = args.delete(:dismiss_options)
      @wrapper_options = args.delete(:wrapper_options)

      verify_callout_setup!

      super(**args.merge(banner_options: build_html_options(args[:banner_options])))
    end
  end
end
