# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::Resources::VersionsResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let(:name) { nil }
  let(:args) { { name: name }.compact }

  let_it_be(:current_user) { create(:user) }
  let(:ctx) { { current_user: current_user } }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:release) { create(:release, project: project, tag: '1.0.0') }
  let_it_be(:version) { create(:ci_catalog_resource_version, catalog_resource: resource, release: release) }

  subject(:result) { resolve(described_class, ctx: ctx, obj: resource, args: args) }

  describe '#resolve' do
    context 'when the user is authorized to read project releases' do
      before_all do
        resource.project.add_guest(current_user)
      end

      context 'when name argument is provided' do
        let(:name) { '1.0.0' }

        it 'returns the version that matches the name' do
          expect(result.items.size).to eq(1)
          expect(result.items.first.name).to eq('1.0.0')
        end
      end
    end
  end
end
