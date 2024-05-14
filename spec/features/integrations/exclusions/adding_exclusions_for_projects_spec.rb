# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Adding and removing exclusions to Beyond Identity integration", :sidekiq_inline, feature_category: :integrations do
  let_it_be_with_reload(:project) { create(:project, :in_subgroup) }
  let_it_be(:admin_user) { create :admin }

  def create_exclusion
    Integrations::Exclusions::CreateService.new(
      current_user: admin_user,
      integration_name: 'beyond_identity',
      projects: [project]
    ).execute
  end

  def destroy_exclusion
    Integrations::Exclusions::DestroyService.new(
      current_user: admin_user,
      integration_name: 'beyond_identity',
      projects: [project]
    ).execute
  end

  context 'when the integration is active for the instance', :enable_admin_mode do
    let(:instance_integration) { create :beyond_identity_integration }

    before do
      ::Integrations::PropagateService.new(instance_integration).execute
    end

    it { expect(project.reload.beyond_identity_integration).to be_activated }

    context 'when the integration is deactivated' do
      before do
        instance_integration.update!(active: false)
        ::Integrations::PropagateService.new(instance_integration).execute
      end

      it { expect(project.reload.beyond_identity_integration).not_to be_activated }
    end

    context 'and the project is excluded from the integration' do
      before do
        create_exclusion
      end

      it { expect(project.reload.beyond_identity_integration).not_to be_activated }

      context 'and the exclusion is removed again' do
        before do
          destroy_exclusion
        end

        it { expect(project.reload.beyond_identity_integration).to be_activated }

        context 'and the exclusion is added again' do
          before do
            create_exclusion
          end

          it { expect(project.reload.beyond_identity_integration).not_to be_activated }
        end
      end
    end
  end

  context 'when the instance integration has not been activated', :enable_admin_mode do
    context 'and an exclusion is created' do
      before do
        create_exclusion
      end

      it { expect(project.reload.beyond_identity_integration).not_to be_activated }

      context 'and the integration is activated for the instance' do
        let(:instance_integration) { create :beyond_identity_integration }

        before do
          ::Integrations::PropagateService.new(instance_integration).execute
        end

        it { expect(project.reload.beyond_identity_integration).not_to be_activated }
      end

      context 'and the exclusion is deleted' do
        before do
          destroy_exclusion
        end

        it { expect(project.reload.beyond_identity_integration).to be_nil }
      end
    end
  end
end
