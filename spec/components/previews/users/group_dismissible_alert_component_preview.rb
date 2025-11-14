# frozen_string_literal: true

module Users
  # @label Group Dismissible Alert
  # @display wrapper false
  class GroupDismissibleAlertComponentPreview < ViewComponent::Preview
    # @label Default Group dismissal
    # @param title text "Alert title (optional)"
    # @param body text "Alert message goes here."
    # @param variant select {{ Pajamas::AlertComponent::VARIANT_ICONS.keys }}
    # @param feature_id select {{ Users::GroupCallout.feature_names.keys }}
    def default(
      title: 'Alert title (optional)',
      body: 'Alert message goes here.',
      variant: :info,
      feature_id: :invite_members_banner
    )
      render(Users::GroupDismissibleAlertComponent.new(
        title: title,
        variant: variant.to_sym,
        dismiss_options: {
          feature_id: feature_id.to_sym, group: FactoryBot.build_stubbed(:group), user: FactoryBot.build_stubbed(:user)
        }
      )) do |c|
        c.with_body { body } if body.present?
      end
    end

    # @label With Wrapper Options
    def with_wrapper
      render(Users::GroupDismissibleAlertComponent.new(
        title: 'Wrapped alert',
        variant: :info,
        dismiss_options: {
          feature_id: :invite_members_banner,
          group: FactoryBot.build_stubbed(:group),
          user: FactoryBot.build_stubbed(:user)
        },
        wrapper_options: { tag: :section, class: 'gl-p-5 gl-bg-gray-10', id: 'wrapped-alert' }
      )) do |c|
        c.with_body do
          'This alert is wrapped in a custom container with additional styling and attributes.'
        end
      end
    end
  end
end
