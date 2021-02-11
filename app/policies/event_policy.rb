# frozen_string_literal: true

class EventPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:visible_to_user) do
    subject.visible_to_user?(user)
  end

  rule { visible_to_user }.enable :read_event
end
