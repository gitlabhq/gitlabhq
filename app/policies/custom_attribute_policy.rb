# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- shared parent for custom attribute policies across multiple bounded contexts (Users, Projects, Namespaces)
# rubocop:disable Gitlab/NamespacedClass -- shared parent for custom attribute policies across multiple bounded contexts (Users, Projects, Namespaces)
class CustomAttributePolicy < BasePolicy
  rule { admin }.policy do
    enable :read_custom_attribute
    enable :update_custom_attribute
    enable :delete_custom_attribute
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Gitlab/BoundedContexts
