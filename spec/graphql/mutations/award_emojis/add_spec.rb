# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AwardEmojis::Add, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let(:project) { create(:project, :public) }
  let(:current_user) { create(:user) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:emoji_name) { 'eyes' }
  let(:args) do
    {
      awardable_id: merge_request.to_global_id,
      name: emoji_name
    }
  end

  describe '#resolve' do
    subject(:resolve) { described_class.new(object: nil, context: query_context, field: nil).resolve(**args) }

    describe 'when awardable is a MR' do
      context 'when project is public' do
        it 'returns the award emoji' do
          result = resolve

          expect(result[:award_emoji]).to be_present
          expect(result[:award_emoji].name).to eq('eyes')
        end

        context 'when merge request visibility is member-only' do
          before do
            project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
          end

          context 'when user is not a member of the project' do
            it 'raises an error' do
              expect do
                resolve
              end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable,
                /You cannot add emoji reactions to this resource/)
            end
          end

          context 'when user is a member of the project' do
            before do
              project.add_developer(current_user)
            end

            it 'returns the award emoji' do
              result = resolve

              expect(result[:award_emoji]).to be_present
              expect(result[:award_emoji].name).to eq('eyes')
            end
          end
        end

        context 'when emoji name is not valid' do
          let(:emoji_name) { 'what_emoji_am_i_?' }

          it 'returns an error' do
            expect(resolve[:errors]).to include('Name is not a valid emoji name')
          end
        end
      end
    end

    describe 'when awardable is an issue' do
      let(:issue) { create(:issue, project: project) }
      let(:args) do
        {
          awardable_id: issue.to_global_id,
          name: emoji_name
        }
      end

      context 'when project is public' do
        it 'returns the award emoji' do
          result = resolve

          expect(result[:award_emoji]).to be_present
          expect(result[:award_emoji].name).to eq('eyes')
        end
      end
    end
  end
end
