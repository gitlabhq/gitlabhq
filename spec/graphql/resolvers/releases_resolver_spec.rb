# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::ReleasesResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:release_v1) { create(:release, project: project, tag: 'v1.0.0') }
  let_it_be(:release_v2) { create(:release, project: project, tag: 'v2.0.0') }
  let_it_be(:developer) { create(:user) }
  let_it_be(:public_user) { create(:user) }

  before do
    project.add_developer(developer)
  end

  describe '#resolve' do
    context 'when the user does not have access to the project' do
      let(:current_user) { public_user }

      it 'returns an empty array' do
        expect(resolve_releases).to eq([])
      end
    end

    context "when the user has full access to the project's releases" do
      let(:current_user) { developer }

      it 'returns all releases associated to the project' do
        expect(resolve_releases).to eq([release_v1, release_v2])
      end
    end
  end

  private

  def resolve_releases
    context = { current_user: current_user }
    resolve(described_class, obj: project, args: {}, ctx: context)
  end
end
