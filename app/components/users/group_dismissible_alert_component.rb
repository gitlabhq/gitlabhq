# frozen_string_literal: true

module Users
  class GroupDismissibleAlertComponent < Pajamas::AlertComponent
    include GroupDismissible

    def initialize(args = {})
      @dismiss_options = args.delete(:dismiss_options)
      @wrapper_options = args.delete(:wrapper_options)

      verify_callout_setup!

      super(**args.merge(dismissible: true, alert_options: build_html_options(args[:alert_options])))
    end
  end
end
