# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores',
    :skip_live_env,
    :requires_admin,
    product_group: :tenant_scale,
    feature_flag: {
      name: 'ui_for_organizations',
      scope: :global
    } do
    describe 'Organization' do
      let(:organization_name) { "organization-#{SecureRandom.hex(8)}" }

      around do |example|
        Runtime::Feature.enable(:ui_for_organizations)
        example.run
        Runtime::Feature.disable(:ui_for_organizations)
      end

      it 'is created', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/436587' do
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
