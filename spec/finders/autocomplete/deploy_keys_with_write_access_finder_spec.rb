# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::DeployKeysWithWriteAccessFinder do
  let_it_be(:user) { create(:user) }

  let(:finder) { described_class.new(user, project) }

  describe '#execute' do
    subject(:execute) { finder.execute }

    context 'when project is missing' do
      let(:project) { nil }

      it 'returns an empty ActiveRecord::Relation' do
        expect(execute).to eq(DeployKey.none)
      end
    end

    context 'when project is present' do
      let_it_be(:project) { create(:project, :public) }

      context 'and current user cannot admin project' do
        it 'raises Gitlab::Access::AccessDeniedError' do
          expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'and current user can admin project' do
        before do
          project.add_maintainer(user)
        end

        context 'when deploy key does not have write access to project' do
          let(:deploy_key_project) { create(:deploy_keys_project, project: project) }

          it 'returns an empty ActiveRecord::Relation' do
            expect(execute).to eq(DeployKey.none)
          end
        end

        context 'when deploy key has write access to project' do
          let(:deploy_key_project) { create(:deploy_keys_project, :write_access, project: project) }

          it 'returns the deploy keys' do
            expect(execute).to match_array([deploy_key_project.deploy_key])
          end
        end
      end
    end
  end
end
