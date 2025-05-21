# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::UserLevelPermissions::UserNamespaceUserLevelPermissionsType, feature_category: :shared do
  it_behaves_like 'expose all user permissions fields for the namespace'
end
