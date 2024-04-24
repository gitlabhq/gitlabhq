# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ReleaseResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:release) { create(:release, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:public_user) { create(:user) }

  let(:args) { { tag_name: release.tag } }

  describe '#resolve' do
    context 'when the user does not have access to the project' do
      let(:current_user) { public_user }

      it 'returns nil' do
        expect(resolve_release).to be_nil
      end
    end

    context "when the user has full access to the project's releases" do
      let(:current_user) { developer }

      it 'returns the release associated with the specified tag' do
        expect(resolve_release).to eq(release)
      end

      context 'when no tag_name argument was passed' do
        let(:args) { {} }

        it 'raises an error' do
          expect { resolve_release }.to raise_error(ArgumentError)
        end
      end
    end
  end

  private

  def resolve_release
    context = { current_user: current_user }
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
