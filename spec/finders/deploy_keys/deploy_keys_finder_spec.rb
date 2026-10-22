# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeys::DeployKeysFinder, feature_category: :continuous_delivery do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

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

      context 'with keys from other organizations' do
        let_it_be(:isolated_organization) { create(:organization, :isolated) }
        let_it_be(:isolated_user) { create(:user, organizations: [isolated_organization]) }
        let_it_be(:isolated_project) do
          create(:project, organization: isolated_organization, maintainers: isolated_user)
        end

        let_it_be(:isolated_accessible_project) do
          create(:project, organization: isolated_organization, developers: isolated_user)
        end

        let_it_be(:other_organization_project_key) do
          create(:deploy_key, organization: create(:organization),
            projects: [accessible_project, isolated_accessible_project])
        end

        let_it_be(:isolated_organization_project_key) do
          create(:deploy_key, organization: isolated_organization,
            projects: [accessible_project, isolated_accessible_project])
        end

        let_it_be(:other_organization_public_key) do
          create(:deploy_key, public: true, organization: create(:organization))
        end

        let_it_be(:isolated_organization_public_key) do
          create(:deploy_key, public: true, organization: isolated_organization)
        end

        context 'when filtering for available project keys' do
          let(:params) { { filter: :available_project_keys } }

          it 'excludes keys from isolated organizations' do
            expect(result.map(&:id)).to match_array(
              [deploy_key_for_accessible_project.deploy_key_id, other_organization_project_key.id]
            )
          end

          context 'when the project organization is isolated' do
            subject(:result) { described_class.new(isolated_project, isolated_user, params).execute }

            it 'returns only keys from the project organization' do
              expect(result.map(&:id)).to match_array([isolated_organization_project_key.id])
            end
          end
        end

        context 'when filtering for available public keys' do
          let(:params) { { filter: :available_public_keys } }

          it 'excludes keys from isolated organizations' do
            expect(result.map(&:id)).to match_array([deploy_key_public.id, other_organization_public_key.id])
          end

          context 'when the project organization is isolated' do
            subject(:result) { described_class.new(isolated_project, isolated_user, params).execute }

            it 'returns only keys from the project organization' do
              expect(result.map(&:id)).to match_array([isolated_organization_public_key.id])
            end
          end
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
