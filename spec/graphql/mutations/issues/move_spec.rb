# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::Move, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:issue) { create(:issue) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:target_project) { create(:project) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    subject(:resolve) { mutation.resolve(project_path: issue.project.full_path, iid: issue.iid, target_project_path: target_project.full_path) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when user does not have permissions' do
      before do
        issue.project.add_developer(current_user)
      end

      it 'returns error message' do
        expect(resolve[:issue]).to eq(nil)
        expect(resolve[:errors].first).to eq('Cannot move issue due to insufficient permissions!')
      end
    end

    context 'when user has sufficient permissions' do
      before do
        issue.project.add_developer(current_user)
        target_project.add_developer(current_user)
      end

      it 'moves issue' do
        expect(resolve[:issue].project).to eq(target_project)
      end
    end
  end
end
