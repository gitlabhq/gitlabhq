# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Projects::Star, feature_category: :groups_and_projects do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user, freeze: true) { create(:user) }

    subject(:mutation) do
      described_class
        .new(object: nil, context: query_context, field: nil)
        .resolve(project_id: project.to_global_id, starred: starred)
    end

    context 'when the user has read access to the project' do
      let_it_be_with_reload(:project) { create(:project, :public) }

      context 'and the project is not starred' do
        context 'and the user stars the project' do
          let(:starred) { true }

          it 'stars the project for the current user' do
            expect(mutation).to include(count: 1)
            expect(project.reset.starrers).to include(current_user)
          end
        end

        context 'and the user unstars the project' do
          let(:starred) { false }

          it 'does not raise an error or change the number of stars' do
            expect(mutation).to include(count: 0)
            expect(project.reset.starrers).not_to include(current_user)
          end
        end
      end

      context 'and the project is starred' do
        before do
          current_user.toggle_star(project)
        end

        context 'and the user stars the project' do
          let(:starred) { true }

          it 'does not raise an error or change the number of stars' do
            expect(mutation).to include(count: 1)
            expect(project.reset.starrers).to include(current_user)
          end
        end

        context 'and the user unstars the project' do
          let(:starred) { false }

          it 'unstars the project for the current user' do
            expect(mutation).to include(count: 0)
            expect(project.reset.starrers).not_to include(current_user)
          end
        end
      end
    end

    context 'when the user does not have read access to the project' do
      let_it_be(:project, freeze: true) { create(:project, :private) }
      let(:starred) { true }

      it 'raises an error' do
        expect { mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        expect(project.starrers).not_to include(current_user)
      end
    end
  end
end
