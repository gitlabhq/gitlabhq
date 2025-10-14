# frozen_string_literal: true

module Users
  # @label Project Dismissible Alert
  # @display wrapper false
  class ProjectDismissibleAlertComponentPreview < ViewComponent::Preview
    # @label Default Project dismissal
    # @param title text "Alert title (optional)"
    # @param body text "Alert message goes here."
    # @param variant select {{ Pajamas::AlertComponent::VARIANT_ICONS.keys }}
    # @param show_icon toggle true
    # @param feature_id select {{ Users::ProjectCallout.feature_names.keys }}
    def default(
      title: 'Alert title (optional)',
      body: 'Alert message goes here.',
      variant: :info,
      show_icon: true,
      feature_id: :awaiting_members_banner
    )
      render(Users::ProjectDismissibleAlertComponent.new(
        title: title,
        variant: variant.to_sym,
        show_icon: show_icon,
        dismiss_options: {
          feature_id: feature_id.to_sym,
          project: FactoryBot.build_stubbed(:project),
          user: FactoryBot.build_stubbed(:user)
        }
      )) do |c|
        c.with_body { body } if body.present?
      end
    end

    # @label With Wrapper Options
    def with_wrapper
      render(Users::ProjectDismissibleAlertComponent.new(
        title: 'Wrapped alert',
        variant: :info,
        dismiss_options: {
          feature_id: :awaiting_members_banner,
          project: FactoryBot.build_stubbed(:project),
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
