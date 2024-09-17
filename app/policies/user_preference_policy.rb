# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Updating this would involve updating multiple dependencies, so should be done with the User module
class UserPreferencePolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass -- Updating this would involve updating multiple dependencies, so should be done with the User module
  delegate { @subject.user }
end
# rubocop:enable Gitlab/BoundedContexts
