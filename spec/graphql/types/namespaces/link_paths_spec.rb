# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths, feature_category: :shared do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  where(:namespace_class, :namespace_type_name) do
    ::Group | ::Types::Namespaces::LinkPaths::GroupNamespaceLinksType
    ::Namespaces::ProjectNamespace | ::Types::Namespaces::LinkPaths::ProjectNamespaceLinksType
    ::Namespaces::UserNamespace | ::Types::Namespaces::LinkPaths::UserNamespaceLinksType
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

  describe '#group' do
    context 'when object is a Group' do
      let_it_be(:group) { create(:group) }

      it 'returns the group itself' do
        resolver = Class.new do
          include Types::Namespaces::LinkPaths

          attr_reader :object

          def initialize(obj)
            @object = obj
          end
        end.new(group)

        expect(resolver.send(:group)).to eq(group)
      end
    end

    context 'when object is a ProjectNamespace' do
      let_it_be(:project) { create(:project) }
      let_it_be(:namespace) { project.project_namespace }

      it 'returns the associated group' do
        resolver = Class.new do
          include Types::Namespaces::LinkPaths

          attr_reader :object

          def initialize(obj)
            @object = obj
          end
        end.new(namespace)

        expect(resolver.send(:group)).to eq(project.group)
      end
    end
  end

  it_behaves_like "expose all link paths fields for the namespace"
end
