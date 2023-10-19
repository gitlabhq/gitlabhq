# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourceResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, :private, namespace: namespace) }
  let_it_be(:resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    context 'when the user can read code on the catalog resource project' do
      before_all do
        namespace.add_developer(user)
      end

      context 'when resource is found' do
        it 'returns a single CI/CD Catalog resource' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { id: resource.to_global_id.to_s })

          expect(result.id).to eq(resource.id)
          expect(result.class).to eq(Ci::Catalog::Resource)
        end
      end

      context 'when resource does not exist' do
        it 'raises ResourceNotAvailable error' do
          result = resolve(described_class, ctx: { current_user: user },
            args: { id: "gid://gitlab/Ci::Catalog::Resource/not-a-real-id" })

          expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when the user cannot read code on the catalog resource project' do
      it 'raises ResourceNotAvailable error' do
        result = resolve(described_class, ctx: { current_user: user },
          args: { id: resource.to_global_id.to_s })

        expect(result).to be_a(::Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
