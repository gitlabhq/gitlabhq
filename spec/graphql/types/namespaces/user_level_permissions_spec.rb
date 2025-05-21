# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::UserLevelPermissions, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  where(:namespace_class, :namespace_type_name) do
    ::Group | ::Types::Namespaces::UserLevelPermissions::GroupNamespaceUserLevelPermissionsType
    ::Namespaces::ProjectNamespace | ::Types::Namespaces::UserLevelPermissions::ProjectNamespaceUserLevelPermissionsType
  end

  with_them do
    describe ".resolve_type" do
      it "knows the correct type for objects" do
        namespace = namespace_class.new

        expect(described_class.resolve_type(namespace, {}))
          .to eq(namespace_type_name)
      end
    end

    describe ".orphan_types" do
      it "includes the type" do
        expect(described_class.orphan_types).to include(namespace_type_name)
      end
    end
  end

  it "raises an error for an unknown type" do
    namespace = build(:project)

    expect { described_class.resolve_type(namespace, {}) }
      .to raise_error("Unknown GraphQL type for namespace type #{namespace.class}")
  end

  it_behaves_like "expose all user permissions fields for the namespace"
end
