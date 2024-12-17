# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project badge', product_group: :tenant_scale do
      let(:badge_name) { "project-badge-#{SecureRandom.hex(8)}" }
      let(:expected_badge_link_url) { "#{Runtime::Scenario.gitlab_address}/#{project.path_with_namespace}" }
      let(:expected_badge_image_url) do
        "#{Runtime::Scenario.gitlab_address}/#{project.path_with_namespace}/badges/main/pipeline.svg"
      end

      let(:project) { create(:project, :with_readme, name: 'badge-test-project') }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      it 'creates project badge',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/350065' do
        Resource::ProjectBadge.fabricate! do |badge|
          badge.name = badge_name
        end

        Page::Project::Settings::Main.perform do |project_settings|
          expect(project_settings).to have_notice('New badge added.')
        end

        Page::Component::Badges.perform do |badges|
          aggregate_failures do
            expect(badges).to have_badge(badge_name)
            expect(badges).to have_visible_badge_image_link(expected_badge_link_url)
            expect(badges.asset_exists?(expected_badge_image_url)).to be_truthy
          end
        end

        project.visit!

        Page::Project::Show.perform do |project|
          expect(project).to have_visible_badge_image_link(expected_badge_link_url)
          expect(project.asset_exists?(expected_badge_image_url)).to be_truthy
        end
      end
    end
  end
end
