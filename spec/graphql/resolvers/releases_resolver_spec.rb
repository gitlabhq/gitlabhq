# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ReleasesResolver do
  include GraphqlHelpers

  let_it_be(:today) { Time.now }
  let_it_be(:yesterday) { today - 1.day }
  let_it_be(:tomorrow) { today + 1.day }

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:release_v1) { create(:release, project: project, tag: 'v1.0.0', released_at: yesterday, created_at: tomorrow) }
  let_it_be(:release_v2) { create(:release, project: project, tag: 'v2.0.0', released_at: today,     created_at: yesterday) }
  let_it_be(:release_v3) { create(:release, project: project, tag: 'v3.0.0', released_at: tomorrow,  created_at: today) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:public_user) { create(:user) }

  let(:args) { { sort: :released_at_desc } }
  let(:all_releases) { [release_v1, release_v2, release_v3] }

  before do
    project.add_developer(developer)
  end

  describe '#resolve' do
    context 'when the user does not have access to the project' do
      let(:current_user) { public_user }

      it 'returns an empty array' do
        expect(resolve_releases).to be_empty
      end
    end

    context "when the user has full access to the project's releases" do
      let(:current_user) { developer }

      it 'returns all releases associated to the project' do
        expect(resolve_releases).to match_array(all_releases)
      end

      describe 'sorting behavior' do
        context 'with sort: :released_at_desc' do
          let(:args) { { sort: :released_at_desc } }

          it 'returns the releases ordered by released_at in descending order' do
            expect(resolve_releases.to_a)
              .to match_array(all_releases)
              .and be_sorted(:released_at, :desc)
          end
        end

        context 'with sort: :released_at_asc' do
          let(:args) { { sort: :released_at_asc } }

          it 'returns the releases ordered by released_at in ascending order' do
            expect(resolve_releases.to_a)
              .to match_array(all_releases)
              .and be_sorted(:released_at, :asc)
          end
        end

        context 'with sort: :created_desc' do
          let(:args) { { sort: :created_desc } }

          it 'returns the releases ordered by created_at in descending order' do
            expect(resolve_releases.to_a)
              .to match_array(all_releases)
              .and be_sorted(:created_at, :desc)
          end
        end

        context 'with sort: :created_asc' do
          let(:args) { { sort: :created_asc } }

          it 'returns the releases ordered by created_at in ascending order' do
            expect(resolve_releases.to_a)
              .to match_array(all_releases)
              .and be_sorted(:created_at, :asc)
          end
        end
      end
    end
  end

  private

  def resolve_releases
    context = { current_user: current_user }
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
