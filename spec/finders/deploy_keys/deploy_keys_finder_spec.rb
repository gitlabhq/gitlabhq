# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeys::DeployKeysFinder, feature_category: :continuous_delivery do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let_it_be(:accessible_project) { create(:project, :internal, developers: user) }
    let_it_be(:inaccessible_project) { create(:project, :internal) }
    let_it_be(:project_private) { create(:project, :private) }

    let_it_be(:deploy_key_for_target_project) do
      create(:deploy_keys_project, project: project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_key_for_accessible_project) do
      create(:deploy_keys_project, project: accessible_project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_key_for_inaccessible_project) do
      create(:deploy_keys_project, project: inaccessible_project, deploy_key: create(:deploy_key))
    end

    let_it_be(:deploy_keys_project_private) do
      create(:deploy_keys_project, project: project_private, deploy_key: create(:another_deploy_key))
    end

    let_it_be(:deploy_key_public) { create(:deploy_key, public: true) }

    let(:params) { {} }

    subject(:result) { described_class.new(project, user, params).execute }

    context 'with access' do
      before_all do
        project.add_maintainer(user)
      end

      context 'when filtering for enabled_keys' do
        let(:params) { { filter: :enabled_keys } }

        it 'returns the correct result' do
          expect(result.map(&:id)).to match_array([deploy_key_for_target_project.deploy_key_id])
        end
      end

      context 'when filtering for available project keys' do
        let(:params) { { filter: :available_project_keys } }

        it 'returns the correct result' do
          expect(result.map(&:id)).to match_array([deploy_key_for_accessible_project.deploy_key_id])
        end
      end

      context 'when filtering for available public keys' do
        let(:params) { { filter: :available_public_keys } }

        it 'returns the correct result' do
          expect(result.map(&:id)).to match_array([deploy_key_public.id])
        end
      end

      context 'when has search' do
        let_it_be(:another_deploy_key_public) { create(:deploy_key, public: true, title: 'new-key') }
        let(:params) { { filter: :available_public_keys, search: 'key', in: 'title' } }

        it 'returns the correct result' do
          expect(result.map(&:id)).to match_array([another_deploy_key_public.id])
        end
      end

      context 'when there are no set filters' do
        it 'returns an empty collection' do
          expect(result).to eq DeployKey.none
        end
      end
    end

    context 'without access' do
      it 'returns an empty collection' do
        expect(result).to eq DeployKey.none
      end
    end
  end
end
