# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::DeployKeysWithWriteAccessFinder, feature_category: :continuous_delivery do
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
          let!(:deploy_key_project) { create(:deploy_keys_project, project: project) }

          it 'returns an empty ActiveRecord::Relation' do
            expect(execute).to eq([])
          end
        end

        context 'when deploy key has write access to project' do
          let!(:deploy_key_project) { create(:deploy_keys_project, :write_access, project: project) }

          it 'returns the deploy keys' do
            expect(execute).to match_array([deploy_key_project.deploy_key])
          end

          context 'when searching by title' do
            let(:query) { SecureRandom.uuid }

            subject(:execute) { finder.execute(title_search_term: query) }

            context 'and there are titles that match' do
              let(:deploy_key) { create(:deploy_key, title: "contains #{query} in title") }
              let!(:deploy_key_project) do
                create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key)
              end

              let!(:non_matching_deploy_key_project) { create(:deploy_keys_project, :write_access, project: project) }

              it 'only returns deploy keys with matching titles' do
                expect(execute).to match_array([deploy_key])
              end
            end
          end
        end
      end
    end
  end
end
