# frozen_string_literal: true

module Admin
  # Alert shown next to a setting that is managed by external configuration and therefore
  # cannot be changed from the Admin UI.
  class ManagedSettingAlertComponent < Pajamas::Component
    private

    # Alert body text, naming the managing party when the configuration declares one.
    #
    # @return [String]
    def message
      managed_by = ::Gitlab::ManagedSettings.managed_by
      return _('This setting is managed and cannot be changed from here.') if managed_by.blank?

      helpers.safe_format(
        _('This setting is managed by %{managed_by} and cannot be changed from here.'),
        managed_by: managed_by
      )
    end
  end
end
