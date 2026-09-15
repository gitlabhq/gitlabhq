# frozen_string_literal: true

module QA
  RSpec.describe 'Tenant Scale',
    :skip_live_env,
    :requires_admin,
    feature_category: :organization,
    quarantine: {
      type: :investigating,
      issue: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/24032'
    },
    feature_flag: {
      name: [:ui_for_organizations, :org_stage_experimental],
      scope: :global
    } do
    describe 'Organization' do
      let(:organization_name) { "organization-#{SecureRandom.hex(8)}" }

      around do |example|
        Runtime::Feature.enable(:ui_for_organizations)
        Runtime::Feature.enable(:org_stage_experimental)
        example.run
        Runtime::Feature.disable(:org_stage_experimental)
        Runtime::Feature.disable(:ui_for_organizations)
      end

      it 'is created' do
        Flow::Login.sign_in

        Page::Main::Menu.perform(&:go_to_create_organization)

        Page::Organization::New.perform do |organization_new|
          organization_new.organization_name = organization_name
          organization_new.create_organization
        end

        Page::Organization::Show.perform do |organization_show|
          expect(organization_show).to have_organization(organization_name)
        end
      end
    end
  end
end
